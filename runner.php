<?php
$max = strtotime("2021-02-27");
$start = strtotime("2021-01-04");

for ($current=$start; $current<=$max; $current += 86400) {
	echo date("Y-m-d", $current) . PHP_EOL;
	exec("serverless invoke local -f job --data '{\"date\": \"" . date("Y-m-d", $current) . "\"}'");
}
