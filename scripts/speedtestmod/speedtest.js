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
            maintainAspectRatio: false,
            scales: {
                y: {
                    beginAtZero: true
                }
            },
            plugins: {
                legend: {
                    position: 'top',
                },
                title: {
                    display: true,
                    text: 'Network Speed Test Results'
                }
            }
        }
    });

    // Load speedtest data
    function loadSpeedtestData() {
        fetch('/admin/api.php?speedtest')
            .then(response => response.json())
            .then(data => {
                if (!data.success) {
                    showMessage('Error loading speedtest data: ' + data.message, 'error');
                    return;
                }

                // Update chart data
                const labels = data.map(item => new Date(item.timestamp).toLocaleString());
                const downloads = data.map(item => item.download);
                const uploads = data.map(item => item.upload);

                speedtestChart.data.labels = labels;
                speedtestChart.data.datasets[0].data = downloads;
                speedtestChart.data.datasets[1].data = uploads;
                speedtestChart.update();

                // Update stats display
                updateStats(data[0]);
            })
            .catch(error => {
                showMessage('Error loading speedtest data: ' + error, 'error');
            });
    }

    // Run speedtest
    $('#run-speedtest').click(function() {
        $(this).prop('disabled', true);
        $('#speedtest-spinner').show();

        fetch('/admin/api.php?speedtest=run', {
            method: 'POST'
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                loadSpeedtestData();
                showMessage('Speedtest completed successfully', 'success');
            } else {
                showMessage('Error running speedtest: ' + data.message, 'error');
            }
        })
        .catch(error => {
            showMessage('Error running speedtest: ' + error, 'error');
        })
        .finally(() => {
            $(this).prop('disabled', false);
            $('#speedtest-spinner').hide();
        });
    });

    // Update interval
    $('#speedtest-interval').change(function() {
        const interval = $(this).val();
        
        fetch('/admin/api.php?speedtest=interval', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ interval: interval })
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                showMessage('Interval updated successfully', 'success');
            } else {
                showMessage('Error updating interval: ' + data.message, 'error');
            }
        })
        .catch(error => {
            showMessage('Error updating interval: ' + error, 'error');
        });
    });

    // Update stats display
    function updateStats(data) {
        if (!data) return;

        const stats = $('.speedtest-stats');
        stats.html(`
            <div class="row">
                <div class="col-4">
                    <h6>Download</h6>
                    <p>${data.download.toFixed(2)} Mbps</p>
                </div>
                <div class="col-4">
                    <h6>Upload</h6>
                    <p>${data.upload.toFixed(2)} Mbps</p>
                </div>
                <div class="col-4">
                    <h6>Ping</h6>
                    <p>${data.ping.toFixed(2)} ms</p>
                </div>
            </div>
            <div class="row">
                <div class="col-12">
                    <h6>Server</h6>
                    <p>${data.server}</p>
                </div>
            </div>
        `);
    }

    // Show message
    function showMessage(message, type) {
        const alert = $('<div class="alert alert-' + type + ' alert-dismissible fade show" role="alert">' +
            message +
            '<button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>' +
            '</div>');
        
        $('.speedtest-stats').after(alert);
        setTimeout(() => alert.alert('close'), 5000);
    }

    // Initial load
    loadSpeedtestData();
});