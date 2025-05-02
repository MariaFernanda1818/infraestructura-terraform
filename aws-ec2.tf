variable "ec2_name" {
  type    = string
  default = "backend-prueba-tecnica"
}

resource "aws_eip" "app" {
  instance = aws_instance.app.id
  vpc      = true
}



# Par de llaves SSH importado desde tu máquina local
resource "aws_key_pair" "deploy" {
  # Identificador del par de llaves en AWS
  key_name = "deploy-key" # ← Nombre con el que AWS reconocerá este key pair
  # Llave pública a importar (ruta local)
  public_key = file("~/.ssh/id_rsa.pub") # ← Lee tu archivo id_rsa.pub y lo sube a AWS
}

# Security Group para controlar el tráfico entrante y saliente
resource "aws_security_group" "sg_http_docker" {
  # Nombre legible del SG en AWS
  name = "http-docker-sg" # ← Identificador humano del SG
  # Descripción de su propósito
  description = "Allow SSH and HTTP" # ← Explica qué puertos abre este SG

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }


  # Regla de ingreso para SSH
  ingress {
    from_port   = 22            # ← Puerto inicial permitido
    to_port     = 22            # ← Puerto final permitido
    protocol    = "tcp"         # ← Protocolo de transporte
    cidr_blocks = ["0.0.0.0/0"] # ← Orígenes permitidos (todos)
  }


  # Regla de salida para todo el tráfico
  egress {
    from_port   = 0             # ← Rango completo de puertos (0)
    to_port     = 0             # ← Rango completo de puertos (0)
    protocol    = "-1"          # ← “-1” = todos los protocolos
    cidr_blocks = ["0.0.0.0/0"] # ← Destinos permitidos (todos)
  }
}

# Data source para encontrar la AMI de Ubuntu 20.04 LTS más reciente
data "aws_ami" "ubuntu" {
  most_recent = true             # ← Selecciona únicamente la AMI más reciente
  owners      = ["099720109477"] # ← Filtro por propietario (Canonical)

  filter {
    name   = "name" # ← Campo de AMI a filtrar
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    # ← Patron de nombre para Ubuntu Focal
  }
}

# Instancia EC2 que instala Docker y levanta tu contenedor
resource "aws_instance" "app" {

  ami = data.aws_ami.ubuntu.id
  # ← ID de la AMI obtenida arriba
  instance_type = "t3.micro" # ← Tamaño de instancia ( Gratis elegible )

  key_name = aws_key_pair.deploy.key_name
  # ← Asocia el key pair “deploy-key” para SSH
  vpc_security_group_ids = [aws_security_group.sg_http_docker.id]
  # ← Aplica el SG que definimos antes

  # Script de arranque que corre al primer boot de la instancia
    user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y docker.io nginx snapd
    snap install core && snap refresh core
    snap install --classic certbot
    ln -s /snap/bin/certbot /usr/bin/certbot

    systemctl enable --now docker
    docker pull mariafernanda2798/prueba-tecnica-backend:latest
    docker run -d --name backend-ms -p 8001:8001 mariafernanda2798/prueba-tecnica-backend

    # Configura solo el proxy HTTP inicialmente
    cat > /etc/nginx/sites-available/default <<EOL
    server {
        listen 80;
        server_name pruebatecnicaback.ddns.net;

        location / {
            proxy_pass http://localhost:8001/;
            proxy_http_version 1.1;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
        }
    }
    EOL


    # Espera y luego ejecuta Certbot (esto añade el bloque HTTPS automáticamente)
    sleep 10
    certbot --nginx --non-interactive --agree-tos \
    --email mariafernandavalencian27@gmail.com \
    -d pruebatecnicaback.ddns.net

    systemctl restart nginx
    EOF


  tags = {
    Name = var.ec2_name
  }

}
