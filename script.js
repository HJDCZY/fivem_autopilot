window.onload = function () {
    var ap = document.getElementById('AP');
    // console.log('AP:', ap);
    var outapsound = document.getElementById('audiooutap');
    window.addEventListener('message', (event) => {
        // console.log(event.data);
        if (event.data.type == 'autopilot') {
            if (event.data.status === 'start') {
                ap.style.display = 'inline-block';
            }
            if (event.data.status == 'stop') {
                if (ap.style.display === 'inline-block'){
                    outapsound.play();
                }
                ap.style.display = 'none';
                // outapsound.play();
            }
        }
    });
};
