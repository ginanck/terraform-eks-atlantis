# GitHub Personal Access Token Setup for Atlantis

## 🔑 Create GitHub Personal Access Token

### Step 1: Go to GitHub Settings
- Navigate to: `https://github.com/settings/tokens`
- Click **"Generate new token"** → **"Generate new token (classic)"**

### Step 2: Configure Token
```
Token name: atlantis-terraform-automation
Expiration: 90 days (or your preference)
```

### Step 3: Select Scopes
**Required permissions:**
- ✅ `repo` - Full control of private repositories
- ✅ `read:user` - Read user profile data  
- ✅ `user:email` - Access user email addresses

### Step 4: Generate and Copy Token
- Click **"Generate token"**
- **Copy the token** (starts with `ghp_`)
- ⚠️ **Save it securely** - you won't see it again!

## 🚀 Deploy Atlantis with PAT

```bash
# 1. Set environment variables
source ./set-env.sh
# Enter your GitHub PAT when prompted

# 2. Deploy Atlantis
make apply PROJECT=terraform-atlantis
```

## 🔗 Configure GitHub Webhook

### Repository Settings
Go to: `https://github.com/ginanck/terraform-eks-atlantis/settings/hooks`

### Add Webhook
- **Payload URL**: `http://atlantis-alb-interview-1345892242.eu-central-1.elb.amazonaws.com/events`
- **Content type**: `application/json`
- **Secret**: `<<github_webhook_secret>>`

### Select Events
- ✅ Pull requests
- ✅ Issue comments
- ✅ Pull request reviews  
- ✅ Pull request review comments

## 🧪 Test Atlantis

1. **Create a test branch**:
   ```bash
   git checkout -b test-atlantis
   ```

2. **Modify a terraform file**:
   ```bash
   echo '# Test comment' >> terraform-atlantis/terraform.tfvars
   git add terraform-atlantis/terraform.tfvars
   git commit -m "Test Atlantis integration"
   git push origin test-atlantis
   ```

3. **Create Pull Request** on GitHub

4. **Check for Atlantis comment** with terraform plan

5. **Comment `atlantis apply`** to apply changes

## 🔍 Troubleshooting

### Check Atlantis Logs
```bash
kubectl logs -f deployment/atlantis -n atlantis
```

### Verify Webhook Delivery
- Go to repository webhook settings
- Check **"Recent Deliveries"** tab
- Look for successful responses (200 status)

### Common Issues
- **401 Unauthorized**: Check PAT has correct permissions
- **404 Repository not found**: Verify repository allowlist in config
- **Webhook not triggering**: Check webhook URL and secret

## 🛡️ Security Notes

- ✅ **Rotate tokens regularly** (every 90 days recommended)
- ✅ **Use environment variables** (never commit tokens to git)
- ✅ **Limit repository access** via allowlist
- ✅ **Monitor token usage** in GitHub settings
