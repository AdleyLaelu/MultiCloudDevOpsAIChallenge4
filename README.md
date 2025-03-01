
# 🛒 CloudMart - MultiCloud, DevOps & AI Challenge
This repository contains the full implementation of CloudMart, a modern e-commerce platform, enhanced with CI/CD pipelines, AI Assistants, and dynamic cloud deployment using AWS and OpenAI services.

## 📌 Project Overview
CloudMart is a multi-cloud e-commerce application developed as part of the MultiCloud, DevOps & AI Challenge. 
The project focuses on:
- Enhancing user experience with AI Assistants, powered by Amazon Bedrock (Claude 3 Sonnet) and OpenAI Assistant.
Amazon Bedrock with Claude 3 Sonnet - This system serves as the primary customer-facing assistant, providing product recommendations and eliminating the need for manual product searches. Customers can simply describe what they're looking for, and the AI will suggest relevant products from the CloudMart catalog.
- OpenAI Assistant - This system handles customer support functions, including answering inquiries and processing order cancellations, replacing traditional customer service interactions with immediate, intelligent responses.
The AI Assistants offer product recommendations, assist with order cancellations, and handle customer queries.
# 🏗️ Architecture Overview
## 🛠 Environments and Technologies Used  🚀 Features
Technology	Purpose

- **AWS EKS	Hosting the application**
- AWS Lambda: Fetching product data from DynamoDB
- Amazon Bedrock: AI product recommendation assistant
- OpenAI Assistant: AI customer support assistant
- Terraform: Infrastructure as Code (IaC)



## 🛠 Environments and Technologies Used
- **Terraform** 🏗️ - Infrastructure as Code (IaC)
- **Amazon Web Services (AWS)** ☁️ - Cloud Provider
- **GitHub Codespaces** 🖥️ - Dev Environment
- **S3** 🗄️ - Cloud Storage
- **DynamoDB** 📊 - NoSQL Database

---
hi

---

## 📜 Step-by-Step Instructions
# **Creating resources using Terraform**
- use Terraform to create a Lambda Function + IAM roles for permissions that enables Amazon Bedrock to communicate with DynamoDB
- Navigate to the folder containing the main.tf file and download the zip file containing the Lambda function that will be used by Bedrock
- 

```bash
cd challenge-day2/backend/src/lambda
cp list_products.zip ../../../../terraform-project/
cd ../../../../terraform-project
```
- Add the following lines at the end of the main.tf file
```bash
# IAM Role for Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "cloudmart_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Lambda function
resource "aws_iam_role_policy" "lambda_policy" {
  name = "cloudmart_lambda_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Scan",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          aws_dynamodb_table.cloudmart_products.arn,
          aws_dynamodb_table.cloudmart_orders.arn,
          aws_dynamodb_table.cloudmart_tickets.arn,
          "arn:aws:logs:*:*:*"
        ]
      }
    ]
  })
}

# Lambda function for listing products
resource "aws_lambda_function" "list_products" {
  filename         = "list_products.zip"
  function_name    = "cloudmart-list-products"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  source_code_hash = filebase64sha256("list_products.zip")

  environment {
    variables = {
      PRODUCTS_TABLE = aws_dynamodb_table.cloudmart_products.name
    }
  }
}

# Lambda permission for Bedrock
resource "aws_lambda_permission" "allow_bedrock" {
  statement_id  = "AllowBedrockInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.list_products.function_name
  principal     = "bedrock.amazonaws.com"
}

# Output the ARN of the Lambda function
output "list_products_function_arn" {
  value = aws_lambda_function.list_products.arn
}
```
# **Configuring the Amazon Bedrock Agent**
## **1️⃣ Install Terraform**

To install Terraform on a **Linux** system, follow these steps:
- manually create the Bedrock Agent for CloudMart:
1. In the Amazon Bedrock console, go to "Model access" in the navigation panel.
2. Choose "Enable specific models".
3. Select the Claude 3 Sonnet model.
   ![Capture d’écran 2025-02-28 135204](https://github.com/user-attachments/assets/f6e70a19-ae95-4ad9-984e-7a56751fb26e)

5. Wait until the model access status changes to "Access granted".
![Capture d’écran 2025-02-28 134904](https://github.com/user-attachments/assets/943cbc63-1b4e-4f6e-87f6-3da1a51bdb08)

- Create the Agent
1. In the Amazon Bedrock console, choose "Agents" under "Builder tools" in the navigation panel.
2. Click on "Create agent".
3. Name the agent "cloudmart-product-recommendation-agent".
4. Select "Claude 3 Sonnet" as the base model.
5. Paste the agent instructions below in the "Instructions for the Agent" section.

```bash
You are a product recommendations agent for CloudMart, an online e-commerce store. Your role is to assist customers in finding products that best suit their needs. Follow these instructions carefully:

1. Begin each interaction by retrieving the full list of products from the API. This will inform you of the available products and their details.

2. Your goal is to help users find suitable products based on their requirements. Ask questions to understand their needs and preferences if they're not clear from the user's initial input.

3. Use the 'name' parameter to filter products when appropriate. Do not use or mention any other filter parameters that are not part of the API.

4. Always base your product suggestions solely on the information returned by the API. Never recommend or mention products that are not in the API response.

5. When suggesting products, provide the name, description, and price as returned by the API. Do not invent or modify any product details.

6. If the user's request doesn't match any available products, politely inform them that we don't currently have such products and offer alternatives from the available list.

7. Be conversational and friendly, but focus on helping the user find suitable products efficiently.

8. Do not mention the API, database, or any technical aspects of how you retrieve the information. Present yourself as a knowledgeable sales assistant.

9. If you're unsure about a product's availability or details, always check with the API rather than making assumptions.

10. If the user asks about product features or comparisons, use only the information provided in the product descriptions from the API.

11. Be prepared to assist with a wide range of product inquiries, as our e-commerce store may carry various types of items.

12. If a user is looking for a specific type of product, use the 'name' parameter to search for relevant items, but be aware that this may not capture all categories or types of products.

Remember, your primary goal is to help users find the best products for their needs from what's available in our store. Be helpful, informative, and always base your recommendations on the actual product data provided by the API.
```

- Configure the IAM Role
1. In the Bedrock Agent overview, locate the 'Permissions' section.
2. Click on the IAM role link. This will take you to the IAM console with the correct role selected.
3. In the IAM console, choose "Add permissions" and then "Create inline policy".
4. In the JSON tab, paste the following policy:
   ```bash
   {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "lambda:InvokeFunction",
      "Resource": "arn:aws:lambda:*:*:function:cloudmart-list-products"
    },
    {
      "Effect": "Allow",
      "Action": "bedrock:InvokeModel",
      "Resource": "arn:aws:bedrock:*::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0"
    }
  ]
}
```
- 
### **Step 1: Add HashiCorp GPG Key**
```sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform

```
1. Replace cloudmart-list-products with the actual name of your Lambda function, if different.
2. Name the policy (for example, "BedrockAgentLambdaAccess") and create it.
3. Verify that the new policy is attached to the role.

   - Configure the Action Group
1. In the "Action groups" section, create a new group called "Get-Product-Recommendations".
2. Set the action group type as "Define with API schemas".
3. Select the Lambda function "cloudmart-list-products" as the action group executor.
4. In the "Action group schema" section, choose "Define via in-line schema editor".
5. Paste the OpenAPI schema below into the schema editor.
```bash
{
    "openapi": "3.0.0",
    "info": {
        "title": "Product Details API",
        "version": "1.0.0",
        "description": "This API retrieves product information. Filtering parameters are passed as query strings. If query strings are empty, it performs a full scan and retrieves the full product list."
    },
    "paths": {
        "/products": {
            "get": {
                "summary": "Retrieve product details",
                "description": "Retrieves a list of products based on the provided query string parameters. If no parameters are provided, it returns the full list of products.",
                "parameters": [
                    {
                        "name": "name",
                        "in": "query",
                        "description": "Retrieve details for a specific product by name",
                        "schema": {
                            "type": "string"
                        }
                    }
                ],
                "responses": {
                    "200": {
                        "description": "Successful response",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "type": "array",
                                    "items": {
                                        "type": "object",
                                        "properties": {
                                            "name": {
                                                "type": "string"
                                            },
                                            "description": {
                                                "type": "string"
                                            },
                                            "price": {
                                                "type": "number"
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    },
                    "500": {
                        "description": "Internal Server Error",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "$ref": "#/components/schemas/ErrorResponse"
                                }
                            }
                        }
                    }
                }
            }
        }
    },
    "components": {
        "schemas": {
            "ErrorResponse": {
                "type": "object",
                "properties": {
                    "error": {
                        "type": "string",
                        "description": "Error message"
                    }
                },
                "required": [
                    "error"
                ]
            }
        }
    }
}
```
- Test the Agent:

1. After creation, use the "Test Agent" panel to have conversations with the chatbot.
2. Verify if the agent is asking relevant questions about the recipient's gender, occasion, and desired category.
3. Confirm if the agent is consulting the API and presenting appropriate product recommendations.


![Capture d’écran 2025-02-28 140540](https://github.com/user-attachments/assets/74109f2b-6db0-4601-a421-380a1943be2d)

## Create an Alias for the Agent:

1. On the agent details page, go to the "Aliases" section.
2. Click on "Create alias".
3. Name the alias "cloudmart-prod".
4. Select the most recent version of the agent.
5. Click on "Create alias" to finalize.
  ## OpenAI Assistant Configuration
1. Access the OpenAI platform (https://platform.openai.com/).
2. Log in or create an account if you don't have one yet.

  ## Create the Assistant:

1. Navigate to the "Assistants" section.
2. Click on "Create New Assistant".
3. Name the assistant "CloudMart Customer Support".
4. Select the model `gpt-4o`. 
![Capture d’écran 2025-02-28 143534](https://github.com/user-attachments/assets/bb5e9b92-16c4-46fd-84d3-a894a50a1fc6)
 
## Generate API Key:

1. Go to the API Keys section in your OpenAI account.
2. Generate a new API key.
3. Copy this key, you'll need it for your environment variables.

## Redeploy the backend with AI Assistants
- Update the cloudmart-backend.yaml file with AI Assistants information
Open the cloudmart-backend.yaml file:
```bash
nano cloudmart-backend.yaml
```   
```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloudmart-backend-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cloudmart-backend-app
  template:
    metadata:
      labels:
        app: cloudmart-backend-app
    spec:
      serviceAccountName: cloudmart-pod-execution-role
      containers:
      - name: cloudmart-backend-app
        image: public.ecr.aws/l4c0j8h9/cloudmaster-backend:latest
        env:
        - name: PORT
          value: "5000"
        - name: AWS_REGION
          value: "us-east-1"
        - name: BEDROCK_AGENT_ID
          value: "xxxx"
        - name: BEDROCK_AGENT_ALIAS_ID
          value: "xxxx"
        - name: OPENAI_API_KEY
          value: "xxxx"
        - name: OPENAI_ASSISTANT_ID
          value: "xxxx"
---

apiVersion: v1
kind: Service
metadata:
  name: cloudmart-backend-app-service
spec:
  type: LoadBalancer
  selector:
    app: cloudmart-backend-app
  ports:
    - protocol: TCP
      port: 5000
      targetPort: 5000
```
# Update the deployment in Kubernetes
```bash
kubectl apply -f cloudmart-backend.yaml
```
![Capture d’écran 2025-02-28 150624](https://github.com/user-attachments/assets/6fb2aa0b-9deb-4b22-922a-f2909c81aec8)

![Capture d’écran 2025-02-28 202855](https://github.com/user-attachments/assets/61361c6a-8e40-45e1-8367-6647edfbe8f6)

![Capture d’écran 2025-02-28 203335](https://github.com/user-attachments/assets/d26611f6-f588-4f98-8d45-014737f72046)

![Capture d’écran 2025-02-28 203457](https://github.com/user-attachments/assets/fd932cba-55cc-4c97-b113-908802f9af2a)





