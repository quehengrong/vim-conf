// A comment should not be part of the function text object.
template <typename T>
T twice(T value) {
  return value + value;
}

template <typename T>
struct Box {
  struct Nested {
    int member;
  };
  T value;
  T get() const {
    auto adjust = [](T x) { return x; };
    return adjust(value);
  }
};

union Storage {
  int integer;
  float real;
};

int last(int first,
         int second) {
  return first + second;
}

#define DO_ONCE(value) do { \
  (value) += 1; \
} while (0)
