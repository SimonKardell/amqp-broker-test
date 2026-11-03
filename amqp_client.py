import os
from uuid import uuid4

from proton import Delivery, Message
from proton.utils import BlockingConnection


def main() -> None:
    print("Starting AMQP client")
    broker_url = os.getenv("AMQP_URL", "amqp://localhost:4242")
    queue_name = os.getenv("AMQP_QUEUE", "test_q")
    dmq_queue_name = os.getenv("DMQ", "test_dmq")
    username = os.getenv("AMQP_USERNAME", "username")
    password = os.getenv("AMQP_PASSWORD", "password")
    timeout = float(os.getenv("AMQP_TIMEOUT", "10"))
    address = f"queue://{queue_name}"
    dmq_address = f"queue://{dmq_queue_name}"

    connection = None
    stage = f"connecting to {broker_url}"
    try:
        connection = BlockingConnection(
            broker_url,
            user=username,
            password=password,
            allowed_mechs="PLAIN",
            reconnect=False,
            timeout=timeout,
        )
        stage = f"attaching receiver to {queue_name}"
        receiver = connection.create_receiver(address, credit=1)
        stage = f"attaching DMQ receiver to {dmq_queue_name}"
        dmq_receiver = connection.create_receiver(dmq_address, credit=1)
        stage = f"attaching sender to {queue_name}"
        sender = connection.create_sender(address)
        message = Message(id=str(uuid4()), body="Test Message", durable=True)
        stage = f"publishing message {message.id} to {queue_name}"
        delivery = sender.send(message, timeout=timeout)
        if delivery.remote_state != Delivery.ACCEPTED:
            raise RuntimeError(f"Broker did not accept the message: {delivery.remote_state}")
        print(f"Published to {queue_name}: {message.body}", flush=True)
        for delivery_number in range(1, 5):
            stage = f"waiting for delivery {delivery_number}/4 from {queue_name} (timeout={timeout}s)"
            msg = receiver.receive(timeout=timeout)
            if msg.id != message.id or msg.body != message.body:
                receiver.reject()
                raise RuntimeError(
                    f"Expected message {message.id}, got {msg.id}; "
                    "the queue may contain older messages or have other consumers"
                )
            print(f"Delivery: {delivery_number}, From: {queue_name}, Content: {msg.body}", flush=True)
            stage = f"requesting redelivery after delivery {delivery_number}/4"
            receiver.reject()
        stage = f"waiting for message {message.id} on DMQ {dmq_queue_name} (timeout={timeout}s)"
        dmq_msg = dmq_receiver.receive(timeout=timeout)
        if dmq_msg.id != message.id or dmq_msg.body != message.body:
            dmq_receiver.release(delivered=False)
            raise RuntimeError(f"Expected DMQ message {message.id}, got {dmq_msg.id}")
        stage = f"acknowledging DMQ message {message.id}"
        dmq_receiver.accept()
        print(f"From DMQ: {dmq_queue_name}, Content: {dmq_msg.body}", flush=True)
        print("PASS: four deliveries followed by delivery to the DMQ", flush=True)
    except Exception as error:
        raise RuntimeError(f"AMQP check failed while {stage}: {error}") from error
    finally:
        if connection is not None:
            connection.close()


if __name__ == "__main__":
    main()