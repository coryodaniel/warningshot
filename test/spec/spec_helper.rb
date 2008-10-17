require 'lib/warningshot'

$test_data  = File.join(%w(. test data))

$log_root = File.join(%w(. test log))
$log_file = File.join($log_root, 'warningshot.log')

FileUtils.mkdir_p $log_root

$logger = Logger.new $log_file
$logger.formatter = WarningShot::LoggerFormatter.new
$logger.level     = Logger::DEBUG