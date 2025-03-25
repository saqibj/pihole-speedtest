<?php
require_once 'auth.php';
require_once 'template.php';

$pageTitle = "Speedtest Settings";
$content = <<<EOT
<div class="row">
    <div class="col-md-12">
        <div class="box" id="speedtest-settings">
            <div class="box-header with-border">
                <h3 class="box-title">Speedtest Settings</h3>
            </div>
            <div class="box-body">
                <div class="form-group">
                    <label for="speedtest-interval">Test Interval (hours):</label>
                    <input type="number" class="form-control" id="speedtest-interval" min="1" max="24" value="6">
                </div>
                <button type="button" class="btn btn-primary" id="save-speedtest-settings">Save Settings</button>
            </div>
        </div>
    </div>
</div>
EOT;

echo $content; 