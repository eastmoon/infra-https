# HTTPS ( 超級文字傳輸安全協定 )

本專案為研究與探討 HTTPS 設定與文獻資料，其系統架構依據[多服務網路伺服器](https://github.com/eastmoon/multiple-service-webserver)為基礎規劃。

+ Nginx ( HTTPS )
  - angular
  - proxy to Server
+ Server ( HTTP )
  - node.js
  - .net core

## 簡介

超文本傳輸安全協定 ( HyperText Transfer Protocol Secure、HTTPS ) 是一種網際網路安全通訊的傳輸協定；其設計基礎是在 HTTP 通訊時，利用 SSL / TLS 對傳輸內容加密，以確保傳輸內容不易受網路竊聽，並基於 SSL 內涵資訊提供網站伺服器的身分認證，亦可透過第三方的 SSL 數位憑證 ( Certificate Authority，CA ) 提供身分驗證與具有公信力的安全資訊認可。

![SSL workflow](https://arip-photo.org/media/ssl/how-does-https-certificate-switching-work-like-on-suche-org.png)

### SSL 設定

+ OpenSSL 生成 KEY

```
docker run -ti -v %cd%\cache\ssl:/var/ssl alpine/openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /var/ssl/nginx.key -out /var/ssl/nginx.crt
```

+ Nginx 設定檔指定金鑰

```
# SSL configuration
ssl_certificate /etc/nginx/ssl/nginx.crt;
ssl_certificate_key /etc/nginx/ssl/nginx.key;
```

+ Ngint 80 轉導至 443 ( 關閉非安全的 80 連接埠)

```
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    # Redirect to HTTPS
    rewrite ^(.*) https://$host$1 permanent;
}
```

+ Nginx 掛入指向 Server 代理設定

```
server {
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    location /node/ {
        proxy_pass http://node:3000/;
    }

    location /dotnet/ {
        proxy_pass http://dotnet:5000/;
    }
}
```
> 嚴苛來說 Nginx 入口走 https，但其後的 Server 維持在 http 協定；在本實驗中可以用 http 連線，但在實務中應避免外部直接存取伺服器的相關連接埠

### 專案指令

+ 操作各專案開發、測試、編譯指令

```
dockerw.bat [angular | node | dotnet] [--dev | --into]
```
> 此功能會啟動獨立編寫用的開發容器

+ 編譯全專案

```
build.bat
```
> 呼叫全部專案 dockerw 指令

+ 操作整合服務

```
service.bat [start | down]
```
> 此功能透過 docker-compose 啟動複數容器來建立主機關係

測試專案是否正常可以使用以下網址

+ https://localhost/
+ https://localhost/node/
    - http://localhost:3000/
+ https://localhost/dotnet/api/values
    - http://localhost:5000/api/values

## 文獻

+ [HTTPS wiki](https://zh.wikipedia.org/wiki/%E8%B6%85%E6%96%87%E6%9C%AC%E4%BC%A0%E8%BE%93%E5%AE%89%E5%85%A8%E5%8D%8F%E8%AE%AE)
    - [TLS wiki](https://zh.wikipedia.org/wiki/%E5%82%B3%E8%BC%B8%E5%B1%A4%E5%AE%89%E5%85%A8%E6%80%A7%E5%8D%94%E5%AE%9A)
+ Nginx
    - [NGINX 設定 HTTPS 網頁加密連線，建立自行簽署的 SSL 憑證](https://blog.gtwang.org/linux/nginx-create-and-install-ssl-certificate-on-ubuntu-linux/)
    - [網址加上 https (設定 SSL)](https://dwatow.github.io/2019/04-16-nginx-https/)
    - [在Nginx上為你的網站加入Https](https://medium.com/@zneuray/%E5%9C%A8nginx%E4%B8%8A%E7%82%BA%E4%BD%A0%E7%9A%84%E7%B6%B2%E7%AB%99%E5%8A%A0%E5%85%A5https-32af0223283a)
+ SSL CA
    - CA 申請
        + [Comodo SSL](https://comodosslstore.com/promoads/cheap-comodo-ssl-certificates.aspx?gclid=Cj0KCQjwiNSLBhCPARIsAKNS4_dgB3p4L0gZvJnqWlHRqBKKq8qPlDF2IL__eOHwak0m7OAeeFmUqc8aAvf4EALw_wcB)
        + [Let’s Encrypt](https://letsencrypt.org/zh-tw/)
    - 文獻
        + [SSL 憑證常見的 6 種問題](https://news.gandi.net/zh-hant/2020/09/7-ssl-certificate-faqs-you-may-have/)
            - [網域名稱 / 網址 / 域名是什麼？有什麼作用？](https://www.net-chinese.com.tw/nc/index.php/MenuLink/Index/AboutDomainName)
            - [HTTPS證書交換是如何工作的（例如在suche.org上）？](https://tw.arip-photo.org/838526-how-does-https-certificate-switching-HYYHKY)
        + [為何HTTPS憑證有貴有便宜還更可以免費？讓我們從CA原理開始講起。](https://progressbar.tw/posts/98)
            - [使用 Let's Encrypt 來申請憑證並且建立憑證鍊](https://aatp.zendesk.com/hc/zh-tw/articles/900004301303)
            - [SSL For Free 免費 SSL 憑證申請，使用 Let’s Encrypt 最簡單方法教學！](https://free.com.tw/ssl-for-free/)
        + [mkcert github](https://github.com/FiloSottile/mkcert)
            - [快速產生本地端開發用SSL憑證工具-mkcert](https://xenby.com/b/205)
            - [Mkcert - 在 localhost 掛 HTTPS 神器](https://w3c.hexschool.com/blog/cd7b449b)
            - [Can I use it on the LAN network?](https://github.com/FiloSottile/mkcert/issues/210)
                + **A cert verifies the domain name not any IP address. The verification happens in your browser or other client though.**
        + [Enabling SSL in your local network](https://anteru.net/blog/2020/enabling-ssl-in-your-local-network/)
            - [Can I be a root certificate authority for my local network?](https://superuser.com/questions/630914)
            - [Create a Certificate Authority and Certificates with OpenSSL](https://codeghar.wordpress.com/2008/03/17/create-a-certificate-authority-and-certificates-with-openssl/)
