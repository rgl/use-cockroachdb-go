# About

[![Build](https://github.com/rgl/use-cockroachdb-go/actions/workflows/main.yml/badge.svg)](https://github.com/rgl/use-cockroachdb-go/actions/workflows/main.yml)

My [CockroachDB](https://github.com/cockroachdb/cockroach) Go example.

# Usage

This can be tested [in docker compose](#usage-docker-compose) or [in a kind kubernetes cluster](#usage-kubernetes).

List this repository dependencies (and which have newer versions):

```bash
GITHUB_COM_TOKEN='YOUR_GITHUB_PERSONAL_TOKEN' ./renovate.sh
```

## Usage (docker compose)

Install docker and docker compose.

Create the environment:

```bash
docker compose up --build --detach
docker compose ps
docker compose logs
```

Start the cockroachdb client:

```bash
docker compose exec cockroachdb cockroach sql --no-line-editor --insecure
```

Execute some commands:

```
-- show information the postgresql version.
select version();
-- list roles.
\dg
-- list databases.
\l
-- insert a quote.
insert into quote(id, author, text, url) values(100, 'Hamlet', 'To be, or not to be, that is the question.', null);
-- select all quotes.
select text || ' -- ' || author as quote from quote;
-- exit
\q
```

Get a quote from the service:

```bash
wget -qO- http://localhost:4000
```

Destroy the environment:

```bash
docker compose down --volumes --remove-orphans --timeout=0
```

## Usage (Kubernetes)

Install docker, kind, kubectl, and helm.

Create the local test infrastructure:

```bash
./.github/workflows/kind/create.sh
```

Access the test infrastructure kind Kubernetes cluster:

```bash
export KUBECONFIG="$PWD/kubeconfig.yml"
kubectl get nodes -o wide
```

Start the cockroachdb client:

```bash
kubectl exec --quiet --stdin --tty statefulset/cockroachdb -- \
    cockroach sql \
        --certs-dir /cockroach/cockroach-certs \
        --no-line-editor
```

Execute some commands:

```
-- show information the postgresql version.
select version();
-- list roles.
\dg
-- list databases.
\l
-- insert a quote.
insert into quote(id, author, text, url) values(100, 'Hamlet', 'To be, or not to be, that is the question.', null);
-- select all quotes.
select text || ' -- ' || author as quote from quote;
-- exit
\q
```

Build and use the use-cockroachdb-go example:

```bash
./build.sh && ./deploy.sh && ./test.sh && xdg-open index.html
```

Destroy the local test infrastructure:

```bash
./.github/workflows/kind/destroy.sh
```

# References

* [CockroachDB homepage](https://www.cockroachlabs.com)
* [CockroachDB source-code](https://github.com/cockroachdb/cockroach)
* [pq Go client](github.com/lib/pq)
* [Cockroach University](https://university.cockroachlabs.com/)
