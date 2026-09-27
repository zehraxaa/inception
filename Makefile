COMPOSE_FILE = srcs/docker-compose.yml
DATA_DIR = /home/ayse/data

all: build up

$(DATA_DIR)/mariadb:
	mkdir -p $(DATA_DIR)/mariadb

$(DATA_DIR)/wordpress:
	mkdir -p $(DATA_DIR)/wordpress

build: $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
	docker compose -f $(COMPOSE_FILE) build

up:
	docker compose -f $(COMPOSE_FILE) up -d

down:
	docker compose -f $(COMPOSE_FILE) down

start:
	docker compose -f $(COMPOSE_FILE) start

stop:
	docker compose -f $(COMPOSE_FILE) stop

clean:
	docker compose -f $(COMPOSE_FILE) down --rmi all 

fclean: 
	docker compose -f $(COMPOSE_FILE) down --rmi all --volumes
	sudo rm -rf $(DATA_DIR)

re: fclean all

.PHONY: all build up down clean fclean re start stop