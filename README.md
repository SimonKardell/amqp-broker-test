# AMQP Redelivery Reproducer

AMQP redelivery is not working with broker image `10.26.0.9163`.
It works with `10.26.0.9054`.

Both images are listed in `docker-compose.yaml`; the broken image is selected
by default. Switch the commented image lines to compare.

With the broker running, Terraform applied, and Python dependencies installed:

```sh
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
python amqp_client.py
```

Expected: four deliveries followed by the same message on the dead-message queue.
