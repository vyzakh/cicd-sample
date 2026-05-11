# CI/CD Sample — GitHub Actions + Docker + AWS ECR

A minimal Node.js/Express app wired up with a full CI/CD pipeline.

```
git push → GitHub Actions → docker build → ECR → SSH deploy → server
```

---

## Project structure

```
cicd-sample/
├── app/
│   ├── index.js            ← Express app
│   ├── index.test.js       ← Jest tests
│   ├── package.json
│   ├── Dockerfile          ← Multi-stage Docker build
│   └── .dockerignore
├── .github/
│   └── workflows/
│       └── deploy.yml      ← CI/CD pipeline
├── server-setup.sh         ← One-time server bootstrap
└── README.md
```

---

## Step 1 — Create an ECR repository

```bash
aws ecr create-repository \
  --repository-name cicd-sample-app \
  --region ap-south-1
```

Note the `repositoryUri` in the output:
```
123456789012.dkr.ecr.ap-south-1.amazonaws.com/cicd-sample-app
```

---

## Step 2 — Create an IAM user for GitHub Actions

1. Go to **IAM → Users → Create user**
2. Attach these policies:
   - `AmazonEC2ContainerRegistryFullAccess`
3. Create an **Access Key** (type: Application running outside AWS)
4. Save the Key ID and Secret

---

## Step 3 — Add GitHub Secrets

Go to your repo → **Settings → Secrets and variables → Actions → New secret**

| Secret name        | Value                                                    |
|--------------------|----------------------------------------------------------|
| `AWS_ACCESS_KEY_ID`     | IAM user access key                                 |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key                                 |
| `AWS_REGION`            | `ap-south-1` (or your region)                       |
| `ECR_REGISTRY`          | `123456789012.dkr.ecr.ap-south-1.amazonaws.com`     |
| `SERVER_HOST`           | Your server's public IP                             |
| `SERVER_USER`           | `ubuntu` (Ubuntu) or `ec2-user` (Amazon Linux)     |
| `SERVER_SSH_KEY`        | Contents of your `~/.ssh/id_rsa` private key        |

---

## Step 4 — Prepare your server (one-time)

SSH into your EC2 / VPS and run:

```bash
bash server-setup.sh
```

This installs Docker and AWS CLI, and configures credentials.

**Tip:** If you're using EC2, attach an IAM role instead of storing credentials:
- Go to EC2 → Instance → Actions → Security → Modify IAM role
- Attach a role with `AmazonEC2ContainerRegistryReadOnly`
- Skip `aws configure` on the server entirely

---

## Step 5 — Push to deploy

```bash
git add .
git commit -m "initial deploy"
git push origin main
```

Watch the pipeline run at: `github.com/<you>/<repo>/actions`

---

## What happens on each push

```
push to main
    │
    ▼
Job 1: test
    npm ci && npm test
    │  (fails here? pipeline stops, nothing deploys)
    ▼
Job 2: build-and-push
    docker build -t <ecr-uri>/cicd-sample-app:<sha> .
    docker push  → ECR (tagged :sha and :latest)
    │
    ▼
Job 3: deploy
    SSH into server
    docker pull <ecr-uri>/cicd-sample-app:latest
    docker stop old container
    docker run  new container on port 80
    ✅ Live at http://<your-server-ip>
```

---

## Local development

```bash
cd app
npm install
npm test          # run tests
npm start         # start server at http://localhost:3000
```

### Run with Docker locally

```bash
cd app
docker build -t cicd-sample-app .
docker run -p 3000:3000 cicd-sample-app
```

---

## Useful commands

```bash
# Check running containers on server
docker ps

# View app logs
docker logs cicd-sample-app -f

# Test the app
curl http://<your-server-ip>/
curl http://<your-server-ip>/health

# Manually pull and restart (emergency)
docker pull <ecr-uri>/cicd-sample-app:latest
docker stop cicd-sample-app && docker rm cicd-sample-app
docker run -d --name cicd-sample-app --restart unless-stopped -p 80:3000 <ecr-uri>/cicd-sample-app:latest
```
