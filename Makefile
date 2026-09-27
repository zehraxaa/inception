COMPOSE_FILE	= srcs/docker-compose.yml
DATA_DIR		= /home/ayse/data
MARIADB_DIR		= $(DATA_DIR)/mariadb
WORDPRESS_DIR	= $(DATA_DIR)/wordpress

.PHONY: all build up down clean fclean re

# Varsayılan hedef: dizinleri oluştur ve servisleri başlat
all: $(MARIADB_DIR) $(WORDPRESS_DIR)
	docker compose -f $(COMPOSE_FILE) up -d --build

# Yalnızca image'ları build et, container başlatma
build: $(MARIADB_DIR) $(WORDPRESS_DIR)
	docker compose -f $(COMPOSE_FILE) build

# Önceden build edilmiş image'larla servisleri başlat
up:
	docker compose -f $(COMPOSE_FILE) up -d

# Container'ları durdur ve kaldır (volume'lar korunur)
down:
	docker compose -f $(COMPOSE_FILE) down

# Container, image ve volume'ları kaldır; data dizinlerini temizle
# Docker volume içindeki dosyalar root sahipli olabilir — alpine container içinden sil
clean: down
	docker compose -f $(COMPOSE_FILE) down --volumes --rmi all 2>/dev/null || true
	@if [ -d "$(MARIADB_DIR)" ]; then \
		docker run --rm -v $(MARIADB_DIR):/target alpine sh -c "rm -rf /target/*" 2>/dev/null || true; \
		rmdir $(MARIADB_DIR) 2>/dev/null || true; \
	fi
	@if [ -d "$(WORDPRESS_DIR)" ]; then \
		docker run --rm -v $(WORDPRESS_DIR):/target alpine sh -c "rm -rf /target/*" 2>/dev/null || true; \
		rmdir $(WORDPRESS_DIR) 2>/dev/null || true; \
	fi

# clean + bütün kullanılmayan Docker kaynaklarını temizle
fclean: clean
	docker system prune -af --volumes 2>/dev/null || true

# Sıfırdan yeniden başlat
re: fclean all

# Data dizinlerini oluşturan implicit kurallar
$(MARIADB_DIR):
	mkdir -p $(MARIADB_DIR)

$(WORDPRESS_DIR):
	mkdir -p $(WORDPRESS_DIR)
