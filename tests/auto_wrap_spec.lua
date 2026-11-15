local config = require("article.config")

-- 1. Test auto_wrap_main logic directly
local raw_c = 'printf("Hello %d\\n", 42);'
local wrapped_c = config.auto_wrap_main("c", raw_c)
assert(wrapped_c:find("int main%(void%)"), "C should be wrapped in main")
assert(wrapped_c:find("stdio.h"), "C should include stdio.h")

-- When main is already present, it should NOT wrap
local complete_c = 'int main(void) { return 0; }'
local unwrapped_c = config.auto_wrap_main("c", complete_c)
assert(unwrapped_c == complete_c, "C with main should remain unchanged")

-- 2. Test C++ auto-wrap
local raw_cpp = 'std::cout << "test" << std::endl;'
local wrapped_cpp = config.auto_wrap_main("cpp", raw_cpp)
assert(wrapped_cpp:find("int main%(%)"), "C++ should be wrapped in main")
assert(wrapped_cpp:find("iostream"), "C++ should include iostream")

-- 3. Test Rust auto-wrap
local raw_rs = 'println!("hello");'
local wrapped_rs = config.auto_wrap_main("rust", raw_rs)
assert(wrapped_rs:find("fn main%(%)"), "Rust should be wrapped in main")

-- 4. Test Go auto-wrap
local raw_go = 'fmt.Println("hello")'
local wrapped_go = config.auto_wrap_main("go", raw_go)
assert(wrapped_go:find("func main%(%)"), "Go should be wrapped in main")
assert(wrapped_go:find("package main"), "Go should include package main")

-- 5. Test Java auto-wrap
local raw_java = 'System.out.println("hello");'
local wrapped_java = config.auto_wrap_main("java", raw_java)
assert(wrapped_java:find("public static void main"), "Java should be wrapped in main")

print("auto_wrap_spec: All auto-wrapping unit tests passed successfully!")
