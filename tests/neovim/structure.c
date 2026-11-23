struct Outer {
  struct Inner {
    int x;
  } inner;
};

union Value { int x; float y; };

int first(int value) {
  return value;
}

int second(void) {
  return 2;
}
