
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

* `APL_CLIENT_ID=SEARCHADS.*******************************`
* `APL_TEAM_ID=SEARCHADS.*******************************`
* `APL_KEY_ID=2864fa90-****-*****-****-****`
* `APL_PRIVATE_KEY_PATH=C:/Users/User/private-key.pem`
* `APL_ACCOUNT_NAME=AccountName`

Эти данные будут использоваться для создания и обновления кеша учётных данных.

## Запрос аккаунтов

Общие данные по своему пользователю и доступным ему рекламным аккаунтам вы можете получить с помощью следующих функций:

* `apl_get_me_details()` - Id пользователя и основной организации
* `apl_get_user_acl()` - Получает роли и организации, к которым есть доступ.

## Запрос объектов рекламных кабинетов

* `apl_get_campaigns()` - Список рекламных кампаний
* `apl_get_ad_groups()` - Список групп объявллений
* `apl_get_ads()` - Список объявлений
* `apl_get_creatives()` - Список креативов

## Запрос отчётов

* `apl_get_campaign_report()` - Отчёт с группировкой по рекламным кампаниям
* `apl_get_ad_group_report()` - Отчёт с группировкой по группам объявлений
* `apl_get_keyword_report()` - Отчёт с группировкой по ключевым словам
* `apl_get_search_term_report()` -  Отчёт с группировкой по поисковым условиям

## Author
Alexey Seleznev, Head of analytics dept. at [Netpeak](https://netpeak.us/)
<Br>Telegram Channel: [R4marketing](https://t.me/R4marketing)
<Br>email: selesnow@gmail.com
<Br>facebook: [facebook.com/selesnow](https://www.facebook.com/selesnow)
<Br>blog: [alexeyseleznev.wordpress.com](https://alexeyseleznev.wordpress.com/)
