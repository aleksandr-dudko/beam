/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.apache.beam.sdk.io.sparkreceiver;

import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.ConnectionFactory;
import com.rabbitmq.client.DefaultConsumer;
import com.rabbitmq.client.Envelope;
import org.apache.beam.vendor.guava.v26_0_jre.com.google.common.util.concurrent.ThreadFactoryBuilder;
import org.apache.spark.storage.StorageLevel;
import org.apache.spark.streaming.receiver.Receiver;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

/**
 * Imitation of Spark {@link Receiver} for RabbitMQ that implements {@link HasOffset} interface. Used to
 * test {@link SparkReceiverIO#read()}.
 */
public class RabbitMqReceiverWithOffset extends Receiver<String> implements HasOffset {

  private static final Logger LOG = LoggerFactory.getLogger(RabbitMqReceiverWithOffset.class);

  private static String RABBITMQ_URL;
  private static String STREAM_NAME;
  private static long TOTAL_MESSAGES_NUMBER;
  private static long startOffset;

  RabbitMqReceiverWithOffset(final String uri, final String streamName, final long totalMessagesNumber) {
    super(StorageLevel.MEMORY_AND_DISK_2());
    RABBITMQ_URL = uri;
    STREAM_NAME = streamName;
    TOTAL_MESSAGES_NUMBER = totalMessagesNumber;
  }

  @Override
  public void setStartOffset(Long startOffset) {
    RabbitMqReceiverWithOffset.startOffset = startOffset != null ? startOffset : 0;
  }

  @Override
  @SuppressWarnings("FutureReturnValueIgnored")
  public void onStart() {
    Executors.newSingleThreadExecutor(new ThreadFactoryBuilder().build()).submit(this::receive);
  }

  @Override
  public void onStop() {
  }

  private void receive() {
    long currentOffset = startOffset;

    final TestConsumer testConsumer;
    final Connection connection;
    final Channel channel;

    try {
      LOG.info("Starting receiver");
      final ConnectionFactory connectionFactory = new ConnectionFactory();
      connectionFactory.setUri(RABBITMQ_URL);
      connectionFactory.setAutomaticRecoveryEnabled(true);
      connectionFactory.setConnectionTimeout(600000);
      connectionFactory.setNetworkRecoveryInterval(5000);
      connectionFactory.setRequestedHeartbeat(60);
      connectionFactory.setTopologyRecoveryEnabled(true);
      connectionFactory.setRequestedChannelMax(0);
      connectionFactory.setRequestedFrameMax(0);
      connection = connectionFactory.newConnection();

      final Map<String, Object> arguments = new HashMap<>();
      arguments.put("x-queue-type", "stream");
      arguments.put("x-stream-offset", currentOffset);

      channel = connection.createChannel();
      channel.queueDeclare(STREAM_NAME, true, false, false, arguments);
      channel.basicQos(100, true);
      testConsumer = new TestConsumer(channel, this::store);

      channel.basicConsume(STREAM_NAME, false, arguments, testConsumer);
    } catch (Exception e) {
      LOG.error("Can not basic consume", e);
      throw new RuntimeException(e);
    }

    while (!isStopped() && testConsumer.getReceived().size() < TOTAL_MESSAGES_NUMBER) {
      try {
        TimeUnit.SECONDS.sleep(1);
      } catch (InterruptedException e) {
        LOG.error("Interrupted", e);
      }
    }

    try {
      LOG.info("Stopping receiver");
      channel.close();
      connection.close();
    } catch (TimeoutException | IOException e) {
      throw new RuntimeException(e);
    }
  }

  /** A simple RabbitMQ {@code Consumer} that stores all received messages. */
  static class TestConsumer extends DefaultConsumer {

    private final List<String> received;
    private final java.util.function.Consumer<String> messageConsumer;

    public TestConsumer(Channel channel, java.util.function.Consumer<String> messageConsumer) {
      super(channel);
      this.received = Collections.synchronizedList(new ArrayList<>());
      this.messageConsumer = messageConsumer;
    }

    @Override
    public void handleDelivery(
            String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) {
      try {
        final String sMessage = new String(body, StandardCharsets.UTF_8);
        LOG.info("adding message to consumer " + sMessage);
        messageConsumer.accept(sMessage);
        received.add(sMessage);

        getChannel().basicAck(envelope.getDeliveryTag(), false);
      } catch (Exception e) {
        LOG.error("Exception during reading from RabbitMQ " + e.getMessage());
      }
    }

    /** Returns a thread safe unmodifiable view of received messages. */
    public List<String> getReceived() {
      return Collections.unmodifiableList(received);
    }
  }
}
