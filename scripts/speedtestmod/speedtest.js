// Speedtest functionality
$(document).ready(function() {
    // Initialize chart
    var speedtestChart = new Chart(document.getElementById('speedtest-chart'), {
        type: 'line',
        data: {
            labels: [],
            datasets: [{
                label: 'Download (Mbps)',
                data: [],
                borderColor: 'rgb(75, 192, 192)',
                tension: 0.1
            }, {
                label: 'Upload (Mbps)',
                data: [],
                borderColor: 'rgb(255, 99, 132)',
                tension: 0.1
            }]
        },
        options: {
            responsive: true,
            scales: {
                y: {
                    beginAtZero: true
                }
            }
        }
    });

    // Load speedtest data
    function loadSpeedtestData() {
        $.getJSON('api.php?speedtest', function(data) {
            var labels = [];
            var downloads = [];
            var uploads = [];

            data.forEach(function(item) {
                labels.push(new Date(item.timestamp).toLocaleString());
                downloads.push(item.download);
                uploads.push(item.upload);
            });

            speedtestChart.data.labels = labels;
            speedtestChart.data.datasets[0].data = downloads;
            speedtestChart.data.datasets[1].data = uploads;
            speedtestChart.update();
        });
    }

    // Run speedtest
    $('#run-speedtest').click(function() {
        $.post('api.php?speedtest=run', function(response) {
            if (response.success) {
                loadSpeedtestData();
                showMessage('Speedtest completed successfully', 'success');
            } else {
                showMessage('Error running speedtest: ' + response.message, 'error');
            }
        });
    });

    // Update interval
    $('#speedtest-interval').change(function() {
        var interval = $(this).val();
        $.post('api.php?speedtest=interval', { interval: interval }, function(response) {
            if (response.success) {
                showMessage('Interval updated successfully', 'success');
            } else {
                showMessage('Error updating interval: ' + response.message, 'error');
            }
        });
    });

    // Save settings
    $('#save-speedtest-settings').click(function() {
        var interval = $('#speedtest-interval').val();
        $.post('api.php?speedtest=interval', { interval: interval }, function(response) {
            if (response.success) {
                showMessage('Settings saved successfully', 'success');
            } else {
                showMessage('Error saving settings: ' + response.message, 'error');
            }
        });
    });

    // Initial load
    loadSpeedtestData();
}); 