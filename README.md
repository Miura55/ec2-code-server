# VSCode Server CDK Development Environment

EC2上にCDK開発環境を構築したVSCode Serverを立てるCloudFormationテンプレートとデプロイスクリプト。

## 前提条件

- AWS CLI がインストール・設定済み
- EC2キーペアが作成済み
- 適切なIAM権限（EC2、VPC、IAM、CloudFormation）

## デプロイ方法

### 1. 基本デプロイ
```bash
./deploy.sh
```

### 2. その他のコマンド
```bash
# スタック状態確認
./deploy.sh status

# アウトプット表示
./deploy.sh outputs

# スタック削除
./deploy.sh delete
```

## アクセス情報

デプロイ完了後、以下の情報でアクセス可能：

- **VSCode Server**: `http://[PublicIP]:8080`
- **パスワード**: `[スタック名]-vscode`
- **SSH**: `ssh -i [キーペア].pem ec2-user@[PublicIP]`

## インストール済みソフトウェア

- Node.js 20 + npm
- AWS CDK
- AWS CLI v2
- Git, Docker, Python3
- VSCode Server + 拡張機能
  - AWS Toolkit
  - TypeScript
  - Python

## 料金目安

- t3.medium: 約$0.0416/時間
- t3.small: 約$0.0208/時間

使用後は必ずスタックを削除してください。