const puppeteer = require('puppeteer');
const { PDFDocument } = require('pdf-lib');
const fs = require('fs').promises;
const path = require('path');

(async () => {
    console.log("Iniciando generación de PDF...");
    const browser = await puppeteer.launch({ 
        headless: true, 
        args: ['--no-sandbox', '--disable-setuid-sandbox'] 
    });
    const page = await browser.newPage();
    
    // Set 16:9 1080p viewport
    await page.setViewport({ width: 1920, height: 1080, deviceScaleFactor: 1 });
    
    const filePath = `file:///${path.resolve(__dirname, 'index.html').replace(/\\/g, '/')}`;
    console.log(`Abriendo: ${filePath}`);
    
    await page.goto(filePath, { waitUntil: 'networkidle0' });
    
    // Hide the HUD controls so they don't appear in the PDF
    await page.evaluate(() => {
        document.getElementById('hud').style.display = 'none';
        document.getElementById('slide-dots').style.display = 'none';
    });

    const screenshots = [];
    const totalSlides = 20;

    for (let i = 0; i < totalSlides; i++) {
        console.log(`Capturando diapositiva ${i + 1}/${totalSlides}...`);
        
        // Wait for entrance animations to complete
        await new Promise(r => setTimeout(r, 1600)); 
        
        const screenshotBuffer = await page.screenshot({ type: 'jpeg', quality: 90 });
        screenshots.push(screenshotBuffer);
        
        if (i < totalSlides - 1) {
            // Trigger next slide via the exact JS function in script.js to ensure it works even with HUD hidden
            await page.evaluate((index) => {
                // The function goTo(index) is in the global scope in script.js?
                // Wait, script.js wrapped everything in DOMContentLoaded.
                // It's safer to dispatch a keydown event for ArrowRight
                document.dispatchEvent(new KeyboardEvent('keydown', {'key': 'ArrowRight'}));
            }, i + 1);
        }
    }

    await browser.close();
    
    console.log("Generando archivo PDF...");
    const pdfDoc = await PDFDocument.create();
    
    for (const buffer of screenshots) {
        const image = await pdfDoc.embedJpg(buffer);
        const { width, height } = image.scale(1);
        const page = pdfDoc.addPage([width, height]);
        page.drawImage(image, {
            x: 0,
            y: 0,
            width: width,
            height: height,
        });
    }

    const pdfBytes = await pdfDoc.save();
    const outputPath = path.join(__dirname, 'Presentacion_ALUNA.pdf');
    await fs.writeFile(outputPath, pdfBytes);
    
    console.log(`¡PDF generado con éxito en: ${outputPath}!`);
})();
