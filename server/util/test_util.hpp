#ifndef ESPY_SERVER_UTIL_TEST_UTIL_HPP_
#define ESPY_SERVER_UTIL_TEST_UTIL_HPP_

#include <memory>
#include <ostream>
#include <sstream>

#include <catch.hpp>
#include <google/protobuf/text_format.h>

namespace espy {

std::ostream& operator<<(std::ostream& os,
                         const google::protobuf::Message& msg) {
  return os << msg.DebugString();
}

}  // namespace espy

namespace test {

// Convenience function for converting a text string into a proto Message of the
// template type.
template <typename Message>
Message ParseProto(std::string text) {
  Message msg;
  if (!google::protobuf::TextFormat::ParseFromString(text, &msg)) {
    FAIL("Failed to parse proto:\n" << text);
  }
  return msg;
}

template <typename Message>
class ProtoMatcher : public Catch::MatcherBase<Message> {
 public:
  ProtoMatcher(Message expected) : expected_(std::move(expected)) {}

  bool match(const Message& actual) const override {
    return expected_.SerializeAsString() == actual.SerializeAsString();
  }

  std::string describe() const override {
    std::ostringstream ss;
    ss << "\ndoes not match:\n" << expected_.DebugString();
    return ss.str();
  }

 private:
  Message expected_;
};

template <typename Message>
ProtoMatcher<Message> EqualsProto(Message&& expected) {
  return ProtoMatcher<Message>(std::move(expected));
}

}  // namespace test

#endif  // ESPY_SERVER_UTIL_TEST_UTIL_HPP_
