/*
  Calling a method through super qualifier.
*/

class c1 {
  int m1() {
    return m2();
  }
  int m2() { return 13; }
}

class c2 extends c1 {
  int m1() { return 22; }
  int m2() { return 23; }
  int m3() {
    return super.m1();
  }
}

class c3 extends c2 {
  int m1() { return 32; }
  int m2() { return 33; }
}

class main {
  main(String[] args) {
    System.out.println((new c3()).m3());
    System.out.println("Done!");
  }
}

public class method_11_super {
  public static void main(String[] args) {
    new main(args);
  }
}