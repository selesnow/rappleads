
# rappleads

<!-- badges: start -->
<!-- badges: end -->

Пакет `rappleads` предоставляет функционал для запроса дыннх из [Apple Ads Campaign Management API](https://developer.apple.com/documentation/apple_ads).

## Установка

На данный момент пакет можно установить из [GitHub](https://github.com/selesnow/rappleads) с помощью команд:

``` r
# install.packages("pak")
pak::pak("selesnow/rappleads")
```

## Авторизация
В [Apple Ads Campaign Management API](https://developer.apple.com/documentation/apple_ads) довольно сложно устроен процесс авторизации, вам необходимо выполнить следующие шаги:

1. Пригласите пользователей с разрешениями API.
2. Сгенерируйте пару закрытый-открытый ключ.
3. Извлеките открытый ключ из сохраненного закрытого ключа.
4. Загрузите открытый ключ.
5. Создайте секрет клиента.
6. Запросите токен доступа.

Пакет `rappleads` за вас решает пункты 5 и 6, но всё остальное вам необходимо выполнить самостоятельно.

### Генерация приватного ключ
После того как вы получили приглашение в рекламные аккаунты вам необходимо сгенерировать приватный ключ. 
Если вы используете MacOS или UNIX-подобную операционную систему, OpenSSL работает автоматически. Если вы используете Windows, вам необходимо скачать [OpenSSL](https://www.openssl.org/).
 
В командной строке выполните команду:

```
openssl ecparam -genkey -name prime256v1 -noout -out private-key.pem
```

### Генерация публичного ключа
Используйте следующую команду для извлечения открытого ключа из сохраненного закрытого ключа:

```
openssl ec -in private-key.pem -pubout -out public-key.pem
```

В вашей рабочей директории будет создан файл public-key.pem. Откройте его в текстовом редакторе и скопируйте открытый ключ, включая начальную и конечную строки.

### Загрузка ключа в Apple Ads

Чтобы загрузить свой открытый ключ, выполните следующие действия:
1. В интерфейсе рекламы выберите «Settings» > «API». Вставьте ключ, созданный в разделе выше, в поле «Public key».
2. Нажмите «Save». 
3. Вы получите необходимые для автоизации учётные данные: clientId, teamId, keyId.

Далее для авторизации вам необходимо создать переменные среды:

* APL_CLIENT_ID=SEARCHADS.*******************************
* APL_TEAM_ID=SEARCHADS.*******************************
* APL_KEY_ID=2864fa90-****-4****-****-****
* APL_PRIVATE_KEY_PATH=C:/Users/User/private-key.pem
* APL_ACCOUNT_NAME=AccountName

Эти данные будут использоваться для создания и обновления кеша учётных данных.

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(rappleads)
## basic example code
```

