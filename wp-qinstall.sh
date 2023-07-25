#!/bin/bash

# Проверка наличия curl
if ! command -v curl &> /dev/null; then
    echo "Ошибка: curl не установлен. Установите curl и повторите попытку." >&2
    exit 1
fi

echo "Загрузка файла с помощью curl..."

# Выполнение команды curl с выводом отладочной информации
curl -v -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar

# Проверка успешности выполнения команды curl
if [ $? -ne 0 ]; then
    echo "Ошибка при выполнении команды curl. Проверьте подключение к интернету и повторите попытку." >&2
    exit 1
fi

echo "Файл успешно загружен."

# Проверка наличия php и выполнение php wp-cli.phar --info
if command -v php &> /dev/null; then
    php wp-cli.phar --info
    wp cli update
else
    echo "Ошибка: PHP не установлен. Установите PHP и повторите попытку." >&2
    exit 1
fi


# Чтение значений из файла .env
if [ -f .env ]; then
    source .env
fi

# Проверка, что все необходимые переменные установлены
if [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ] || [ -z "$DB_HOST" ] || \
   [ -z "$SITE_URL" ] || [ -z "$ADMIN_USER" ] || [ -z "$ADMIN_EMAIL" ] || [ -z "$ADMIN_PASSWORD" ]; then
    echo "Ошибка: Не все необходимые переменные установлены в файле .env." >&2
    exit 1
fi

# Проверка пользователя (если пользователь - root, выполняем от имени root, в противном случае - от имени текущего пользователя)
if [ "$(id -u)" -eq 0 ]; then
    # Выполнение команды от имени root (администратора)
    wp core download --locale=ru_RU --allow-root
    
    # Выполнение команды wp config create с использованием значений из файла .env
    php wp-cli.phar config create --dbname="$DB_NAME" --dbuser="$DB_USER" --dbpass="$DB_PASSWORD" --dbhost="$DB_HOST" --allow-root
    # Выполнение команды wp core install с использованием переменных из файла .env
    php wp-cli.phar core install --url="$SITE_URL" --title="My Website" --admin_user="$ADMIN_USER" --admin_email="$ADMIN_EMAIL" --admin_password="$ADMIN_PASSWORD" --allow-root
else
    # Выполнение команды от имени текущего пользователя
    wp core download --locale=ru_RU
    
    # Выполнение команды wp config create с использованием значений из файла .env
    php wp-cli.phar config create --dbname="$DB_NAME" --dbuser="$DB_USER" --dbpass="$DB_PASSWORD" --dbhost="$DB_HOST"
    php wp-cli.phar core install --url="$SITE_URL" --title="My Website" --admin_user="$ADMIN_USER" --admin_email="$ADMIN_EMAIL" --admin_password="$ADMIN_PASSWORD"
fi

# Проверка и установка плагинов из списка, заданного в PLUGINS_LIST
if [ -n "$PLUGINS_LIST" ]; then
    plugins=$(echo "$PLUGINS_LIST" | tr ',' '\n')
    for plugin in $plugins; do
        php wp-cli.phar plugin install "$plugin" --activate --allow-root
    done
fi


