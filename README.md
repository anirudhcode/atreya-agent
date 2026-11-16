# Hermes — Phase 1 Infrastructure

Spot-only Graviton instance in `ap-south-1`, single AZ, persistent `/data` EBS
volume, WireGuard-only access, spot-interruption plumbing (EventBridge → SQS +
ASG lifecycle hook). The Go interruption consumer is Phase 1 step 6 (next).

## One-time setup

### 1. WireGuard keys

```sh
# server keypair
wg genkey | tee /dev/stderr | wg pubkey > server_public.key
# ^ prints the private key to stderr. Copy it. You'll paste it into SSM in step 3.

# Mac keypair (private stays on the Mac; public goes to terraform.tfvars)
wg genkey | tee mac_private.key | wg pubkey > mac_public.key
```

Do not save the server private key to a file. If you already did, delete it
after step 3.

### 2. terraform.tfvars

Both values here are PUBLIC keys.

```sh
cp terraform.tfvars.example terraform.tfvars
# set ssh_public_key          = contents of ~/.ssh/id_ed25519.pub
# set wireguard_client_pubkey = contents of mac_public.key
```

### 3. Apply + seed the secret

```sh
terraform init
terraform apply
```

Terraform creates the SSM parameter with a placeholder. Now push the real key:

```sh
aws ssm put-parameter \
  --region ap-south-1 \
  --name '/hermes/wireguard/server_private_key' \
  --type SecureString \
  --key-id alias/hermes-secrets \
  --overwrite \
  --value '<paste server private key>'
```

Then cycle the ASG so the first instance boots with the real key:

```sh
aws autoscaling start-instance-refresh \
  --region ap-south-1 \
  --auto-scaling-group-name hermes-asg
```

The private key now exists only in SSM (encrypted with the project CMK). It
never enters Terraform state, tfvars, the repo, or any local file.

Note the `wireguard_endpoint` output (`<EIP>:51820`).

### 4. Mac WireGuard config

`/opt/homebrew/etc/wireguard/wg0.conf` (or import via the WireGuard app):

```ini
[Interface]
Address = 10.0.0.2/24
PrivateKey = <contents of mac_private.key>

[Peer]
PublicKey = <contents of server_public.key>
Endpoint = <EIP>:51820
AllowedIPs = 10.0.0.0/24        # split tunnel: only the WG subnet
PersistentKeepalive = 25
```

Bring it up: `sudo wg-quick up wg0` (launchd autostart is Phase 6).

## Verify (Phase 1 exit criteria)

```sh
ping 10.0.0.1                    # server WG address
ssh ubuntu@10.0.0.1              # SSH only works through the tunnel
```

On the box, confirm the persistent volume mounted:

```sh
df -h /data                      # ext4 on the attached EBS volume
```

**EBS persistence test:** write a marker, kill the instance, confirm it
survives the replacement:

```sh
ssh ubuntu@10.0.0.1 'echo alive > /data/marker && cat /data/marker'
aws autoscaling terminate-instance-in-auto-scaling-group \
  --instance-id <id> --no-should-decrement-desired-capacity
# wait for the replacement, tunnel reconnects to the same EIP
ssh ubuntu@10.0.0.1 'cat /data/marker'   # -> alive
```

## Tailscale (reliable private access)

WireGuard needs a reachable peer endpoint and breaks when the Mac roams; and
the security group + host firewall already block all public inbound except
`51820/udp`, so WG is the only way in — a single point of failure. Tailscale
adds a second, self-healing path (NAT traversal + DERP relay) with no inbound
port and no security-group change.

Provisioning installs Tailscale and rejoins the tailnet on every boot using a
reusable, non-expiring auth key from SSM. Node identity lives on `/data`, so
the same node (and MagicDNS name) survives spot replacement.

One-time setup:

```sh
# 1. Create a reusable, non-expiring auth key in the Tailscale admin console
#    (Settings -> Keys), ideally tagged (e.g. tag:hermes).
# 2. Push it to SSM (same pattern as the other secrets):
aws ssm put-parameter --region ap-south-1 \
  --name '/hermes/tailscale/auth_key' --type SecureString \
  --key-id alias/hermes-secrets --overwrite \
  --value 'tskey-auth-...'
# 3. Apply, then cycle the ASG so the instance rejoins:
terraform apply
aws autoscaling start-instance-refresh \
  --region ap-south-1 --auto-scaling-group-name hermes-asg
```

Connect from the Mac (install Tailscale, same account). The box is reachable at
`hermes-box.<tailnet>.ts.net` (or its `100.x` address). In the Hermes desktop
app: **Settings -> Gateways -> Add -> Remote gateway** ->
`http://hermes-box.<tailnet>.ts.net:9119`, signing in with the dashboard
credentials (`admin` + `hermes_dashboard_password`).

The dashboard now binds `0.0.0.0`; ufw still allows only `wg0`, `tailscale0`,
and the WG handshake port, so nothing is exposed publicly.

## Notes / decisions baked in

- **Single AZ** (`availability_zone`): forced by the SQLite-on-EBS requirement.
  Defaults to `ap-south-1b`; moved off `ap-south-1a` after repeated spot
  `UnfulfillableCapacity` errors. To switch AZ: scale the ASG to 0, snapshot
  `/data`, `terraform state rm aws_ebs_volume.data` (it's `prevent_destroy`),
  set `data_snapshot_id` + `availability_zone`, then apply.
- **Spot only**: `on_demand_percentage_above_base_capacity = 0`. Full spot
  drought = agent offline, no on-demand surprise bill (per plan).
- **EIP** is associated in `user_data`, not by Terraform, so it re-binds after
  every spot replacement.
- **First boot** formats `/data`. Every later boot mounts the existing fs.
- **Break-glass**: if WireGuard is down, SSM Session Manager still works
  (`AmazonSSMManagedInstanceCore` is attached).

## Publishing this repo

Safe to commit: all `.tf` files, `templates/`, `terraform.tfvars.example`,
`.gitignore`, `.terraform.lock.hcl`.

Never committed (gitignored): `terraform.tfvars`, `*.tfstate*`, `*.key`,
`.terraform/`.

Secret handling guarantees:
- Public keys (SSH, WG client) are not secrets; publishing them is harmless.
- The WG server private key exists only in SSM, encrypted with a project CMK.
  It is never in a local file, never in the repo, never in Terraform state.
- The CMK key policy restricts `kms:Decrypt` to the instance role, and only
  when called via SSM (`kms:ViaService`). An IAM admin who reads the SSM
  parameter without a separate KMS grant gets ciphertext.
- On the instance, the WireGuard config lives on a tmpfs mount (`/etc/wireguard`).
  The private key exists only in RAM and is gone on termination.
- Terraform state holds no plaintext secret. State is still gitignored because
  it exposes resource attributes (ARNs, IPs) you needn't publish.

## Secret pattern for later phases

Fireworks API key (Phase 2) and MCP credentials (Phase 4) follow the same rule:
never let Terraform manage the value. For each, create the parameter shell with
`ignore_changes = [value]` and push the real value via `aws ssm put-parameter`
(or AWS Secrets Manager). The instance reads them at runtime through its IAM
role. Nothing sensitive touches tfvars, state, or the repo.
