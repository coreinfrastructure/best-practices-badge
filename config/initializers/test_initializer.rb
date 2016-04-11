p "Test instances before test_initializer: #{Test.count}"
Test.instantiate
p "Test instances after test_initializer: #{Test.count}"
