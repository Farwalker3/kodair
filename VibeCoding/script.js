document.addEventListener('DOMContentLoaded', () => {
    // DOM Elements
    const tabButtons = document.querySelectorAll('.tab-btn');
    const panels = document.querySelectorAll('.panel');
    const runButton = document.getElementById('run-btn');
    const previewFrame = document.getElementById('preview-frame');
    const htmlCode = document.getElementById('html-code');
    const cssCode = document.getElementById('css-code');
    const jsCode = document.getElementById('js-code');

    // Default content
    htmlCode.value = '<!DOCTYPE html>\n<html>\n<head>\n  <title>My Code</title>\n</head>\n<body>\n  <h1>Hello, World!</h1>\n  <p>Start coding here...</p>\n</body>\n</html>';
    cssCode.value = 'body {\n  font-family: Arial, sans-serif;\n  margin: 20px;\n  line-height: 1.6;\n}\n\nh1 {\n  color: #2c3e50;\n}';
    jsCode.value = '// Your JavaScript code here\nconsole.log("Hello from JavaScript!");';

    // Tab switching functionality
    tabButtons.forEach(button => {
        button.addEventListener('click', () => {
            // Remove active class from all buttons and panels
            tabButtons.forEach(btn => btn.classList.remove('active'));
            panels.forEach(panel => panel.classList.remove('active'));
            
            // Add active class to clicked button and corresponding panel
            button.classList.add('active');
            const tabName = button.getAttribute('data-tab');
            document.getElementById(`${tabName}-panel`).classList.add('active');
        });
    });

    // Run code and update preview
    function updatePreview() {
        // Get the iframe document
        const previewDocument = previewFrame.contentDocument || previewFrame.contentWindow.document;
        
        // Create the HTML content with embedded CSS and JS
        const htmlContent = `
            ${htmlCode.value}
            <style>${cssCode.value}</style>
            <script>${jsCode.value}</script>
        `;
        
        // Write to the iframe document
        previewDocument.open();
        previewDocument.write(htmlContent);
        previewDocument.close();
    }

    // Run button click event
    runButton.addEventListener('click', updatePreview);

    // Auto-update preview (optional, can be resource-intensive)
    let debounceTimer;
    const autoUpdate = (e) => {
        clearTimeout(debounceTimer);
        debounceTimer = setTimeout(updatePreview, 1000); // 1 second delay
    };

    // Add event listeners for auto-update
    htmlCode.addEventListener('input', autoUpdate);
    cssCode.addEventListener('input', autoUpdate);
    jsCode.addEventListener('input', autoUpdate);

    // Initial preview update
    updatePreview();
});