# tailspikedb
Code and data used to build the website https://jianglabnlm.com/tailspikedb/

# File content
```
.
├── app
│   ├── about.html
│   ├── data
│   ├── download.html
│   ├── footer.html
│   ├── search.html
│   ├── server.R
│   ├── ui.R
│   └── www
├── docker-compose.yml
├── etc
│   └── letsencrypt
├── LICENSE
├── log
├── nginx
│   └── nginx.conf
├── README.md
├── tailspikedb
│   └── Dockerfile
├── var
│   ├── lib
│   └── log
└── website_tpl
    ├── 404.html
    └── _site
```

# Prerequist
- [Docker](https://www.docker.com/)

# Build this website
```
git clone git@github.com:nlm-irp-jianglab/tailspikedb.git
cd tailspikedb/
docker compose up --build -d
```