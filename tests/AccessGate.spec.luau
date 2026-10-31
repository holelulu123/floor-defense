local AccessGate = require("../src/shared/AccessGate")

assert(AccessGate.matches("open sesame", "open sesame"), "exact match")
assert(AccessGate.matches("  open sesame ", "open sesame"), "spaces around are ignored")
assert(not AccessGate.matches("Open Sesame", "open sesame"), "case-sensitive")
assert(not AccessGate.matches("", "open sesame"), "empty never matches")
assert(not AccessGate.matches("x", nil), "no password set never matches")
assert(not AccessGate.matches(42, "42"), "only strings")
assert(not AccessGate.matches(string.rep("a", 65), string.rep("a", 65)), "too long")
assert(AccessGate.clean("  hi ") == "hi", "clean trims")

print("AccessGate: ok")
