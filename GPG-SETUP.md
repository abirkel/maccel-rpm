# GPG Key Setup for RPM Package Signing

This guide explains how to set up GPG signing for the maccel RPM packages. Package signing ensures users can verify the authenticity and integrity of the packages they install.

## Overview

The build workflow signs all RPM packages using GPG. The private key is encrypted and stored in GitHub Secrets, while the public key is distributed in this repository for users to verify packages.

## 1. Generate GPG Key

Generate a new GPG key pair specifically for signing RPM packages:

```bash
gpg --full-generate-key
```

**Recommended parameters:**
- Key type: `(1) RSA and RSA`
- Key size: `4096` bits
- Expiration: `0` (does not expire) or set a reasonable expiration like `2y`
- Real name: `Maccel RPM Signing Key` (or your name)
- Email: Your email address
- Comment: `RPM package signing` (optional)

**Example interaction:**
```
Please select what kind of key you want:
   (1) RSA and RSA (default)
Your selection? 1

RSA keys may be between 1024 and 4096 bits long.
What keysize do you want? (3072) 4096

Please specify how long the key should be valid.
Key is valid for? (0) 0

Real name: Maccel RPM Signing Key
Email address: your-email@example.com
Comment: RPM package signing
```

After entering the information, you'll be prompted to set a passphrase. **Choose a strong passphrase** - you'll need it for encryption and GitHub Secrets.

## 2. Export Keys

### Export Private Key

Find your key ID:
```bash
gpg --list-secret-keys --keyid-format=long
```

Output will look like:
```
sec   rsa4096/ABCD1234EFGH5678 2024-01-01 [SC]
      1234567890ABCDEF1234567890ABCDEF12345678
uid                 [ultimate] Maccel RPM Signing Key <your-email@example.com>
ssb   rsa4096/IJKL9012MNOP3456 2024-01-01 [E]
```

The key ID is `ABCD1234EFGH5678` (or use the full fingerprint).

Export the private key:
```bash
gpg --export-secret-keys --armor ABCD1234EFGH5678 > private.key
```

### Export Public Key

Export the public key to the repository:
```bash
gpg --export --armor ABCD1234EFGH5678 > RPM-GPG-KEY-maccel
```

## 3. Encode Private Key for GitHub Secrets

The exported private key is already encrypted with your GPG passphrase. Encode it to base64 for GitHub Secrets:

```bash
base64 -w 0 private.key > private.key.b64
```

On macOS, use:
```bash
base64 -i private.key -o private.key.b64
```

## 4. Configure GitHub Secrets

Add the following secrets to your GitHub repository:

### Required Secrets

1. **GPG_PRIVATE_KEY**
   - Value: Contents of `private.key.b64` (the base64-encoded private key)
   - Copy the entire output: `cat private.key.b64`

2. **GPG_PASSPHRASE**
   - Value: Your GPG key passphrase (the same one used for key generation and encryption)

3. **GPG_KEY_ID**
   - Value: Your GPG key ID (e.g., `ABCD1234EFGH5678`) or email address

### Adding Secrets to GitHub

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret:
   - Name: `GPG_PRIVATE_KEY`
   - Value: Paste the base64-encoded private key
   - Click **Add secret**
5. Repeat for `GPG_PASSPHRASE` and `GPG_KEY_ID`

## 5. Commit Public Key

Add and commit the public key to the repository:

```bash
git add RPM-GPG-KEY-maccel
git commit -m "feat: add GPG public key for package verification" && git push
```

The public key will be used by users to verify package signatures.

## 6. Clean Up

**Important:** Securely delete the temporary files:

```bash
shred -u private.key private.key.b64
```

On macOS (shred not available):
```bash
rm -P private.key private.key.b64
```

Or use:
```bash
rm private.key private.key.b64
```

**Keep your GPG key in your local keyring** - you may need it for future operations.

## Verification

### Test Import Locally

Before committing secrets, verify the process works:

```bash
# Decode the base64 key
echo "YOUR_BASE64_CONTENT" | base64 -d > test.key

# Import and verify (will prompt for passphrase)
gpg --import test.key
gpg --list-keys

# Clean up
rm test.key
```

### Verify Workflow Integration

After setting up secrets:

1. Manually trigger the `build-rpm.yml` workflow with `force_rebuild: true`
2. Check the workflow logs for the "Setup GPG for signing" step
3. Verify the "Sign RPM packages" step completes successfully
4. Download the built RPMs and check signatures:

```bash
rpm -qip maccel-*.rpm | grep Signature
```

## User Verification

Users will verify packages using the public key:

```bash
# Import public key
rpm --import https://raw.githubusercontent.com/USERNAME/maccel-rpm/main/RPM-GPG-KEY-maccel

# Verify package signature
rpm -K maccel-*.rpm
```

Expected output:
```
maccel-0.5.6-1.fc40.x86_64.rpm: digests signatures OK
```

## Troubleshooting

### "gpg: decryption failed: Bad session key"
- Verify the passphrase is correct in GitHub Secrets
- Ensure you're using the same passphrase from GPG key generation

### "gpg: no valid OpenPGP data found"
- Check base64 encoding/decoding is correct
- Verify the private key file is not corrupted

### "rpm --addsign" fails
- Ensure GPG_KEY_ID matches the imported key
- Check that the key is trusted (trust level set in workflow)
- Verify GPG agent is running in the container

### Key not found during signing
- Confirm the key was imported successfully in the workflow
- Check that GPG_KEY_ID in secrets matches the actual key ID
- Review workflow logs for import errors

## Security Considerations

1. **Passphrase strength**: Use a strong, unique passphrase for the GPG key
2. **Secret rotation**: Consider rotating keys periodically (e.g., annually)
3. **Access control**: Limit who has access to repository secrets
4. **Key backup**: Keep a secure backup of your GPG key outside of GitHub
5. **Revocation**: If compromised, revoke the key and generate a new one

## Key Rotation

When rotating keys:

1. Generate a new GPG key pair (follow steps 1-3)
2. Update GitHub Secrets with new base64-encoded key and passphrase
3. Export and commit new public key as `RPM-GPG-KEY-maccel`
4. Optionally: Keep old public key as `RPM-GPG-KEY-maccel-old` for verifying older packages
5. Announce the key change to users

## References

- [RPM Package Signing](https://rpm-packaging-guide.github.io/#signing-packages)
- [GPG Documentation](https://www.gnupg.org/documentation/)
- [GitHub Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
