/*
  Same as WaitNotifyQueue, but the consumer thread is itnerrupted at the end of main().
  7 solutions expected:
  - 4 non-interruption solutions:
      put put get put get get
      put put get get put get
      put get put put get get
      put get put get put get
  + 3 solutions involving interruption. Not every get at the end of a sequence above may lead to an interruption.
    Only those get-s that could block on an empty queue.
*/
public class WaitNotifyQueueInterrupt {
  public static void main(String[] args) throws Exception {
    final BlockingQueue queue = new BlockingQueue();
    Thread t2 = new Thread() {
      public void run() {
        for(int i=0; i<3; i++) {
          try {
            queue.get();
          } catch(InterruptedException e) {
            System.out.println("Interrupted.");
            return;
          }
        }
      }
    };
    t2.start();
    for(int i=0; i<3; i++) {
      queue.put(i);
    }
    t2.interrupt();
  }

  static class BlockingQueue {
    int capacity = 2;
    int[] array = new int[capacity];
    int head=0, tail=0;
    synchronized void put(int element) throws InterruptedException {
      while((tail-head) == capacity) {
        wait();
      }
      array[tail++ % capacity]=element;
      System.out.print("put-" + element + " ");
      notify();
    }
    synchronized int get() throws InterruptedException {
      while((tail-head) == 0) {
        wait();
      }
      int element = array[head++ % capacity];
      System.out.print("get-" + element + " ");
      notify();
      return element;
    }
  }
}
