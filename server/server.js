const http = require('http');

const PORT = process.env.PORT || 3000;

/**
 * Mansur Hoca'nın belirttiği 7 Girdili Algoritma Fonksiyonu.
 * Şimdilik toplama/çıkarma işlemi yapar.
 * Formül değiştiğinde SADECE bu fonksiyon revize edilir.
 */
function executeAlgorithm(inputs) {
  const x1 = parseFloat(inputs.x1) || 0;
  const x2 = parseFloat(inputs.x2) || 0;
  const x3 = parseFloat(inputs.x3) || 0;
  const x4 = parseFloat(inputs.x4) || 0;
  const x5 = parseFloat(inputs.x5) || 0;
  const x6 = parseFloat(inputs.x6) || 0;
  const x7 = parseFloat(inputs.x7) || 0;

  // Algoritma: (x1 + x2 + x3 + x4) - (x5 + x6 + x7)
  const sumGroup = x1 + x2 + x3 + x4;
  const subGroup = x5 + x6 + x7;
  const finalOutput = sumGroup - subGroup;

  return {
    output: parseFloat(finalOutput.toFixed(2)),
    formula: `(${x1} + ${x2} + ${x3} + ${x4}) - (${x5} + ${x6} + ${x7})`,
    details: `Toplanan Grup: ${sumGroup.toFixed(2)}, Çıkarılan Grup: ${subGroup.toFixed(2)}`,
    isSafe: finalOutput >= 0,
    timestamp: new Date().toISOString()
  };
}

const server = http.createServer((req, res) => {
  // CORS başlıkları (Mobil, Web ve Emülatör erişimi için)
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // Health check / Durum kontrolü
  if (req.method === 'GET' && (req.url === '/' || req.url === '/api/health')) {
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify({
      status: 'online',
      message: 'ENG401 İnşaat Mühendisliği Hesaplama Web Servisi Aktif',
      endpoint: '/api/calculate'
    }));
    return;
  }

  // 7 Girdi Alıp 1 Çıktı Dönen POST Servisi
  if (req.method === 'POST' && req.url === '/api/calculate') {
    let body = '';
    req.on('data', chunk => {
      body += chunk.toString();
    });

    req.on('end', () => {
      try {
        const payload = JSON.parse(body || '{}');
        const inputs = payload.inputs || payload;

        console.log(`[${new Date().toLocaleTimeString()}] Mobil cihazdan 7 girdi alındı:`, inputs);

        const calculation = executeAlgorithm(inputs);

        console.log(`[${new Date().toLocaleTimeString()}] Hesaplanan 1 çıktı:`, calculation.output);

        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({
          status: 'success',
          output: calculation.output,
          formula: calculation.formula,
          details: calculation.details,
          isSafe: calculation.isSafe,
          receivedInputs: inputs,
          timestamp: calculation.timestamp
        }));
      } catch (err) {
        res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({
          status: 'error',
          message: 'Geçersiz JSON verisi: ' + err.message
        }));
      }
    });
    return;
  }

  // Bulunamadı (404)
  res.writeHead(404, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify({ status: 'error', message: 'Endpoint bulunamadı' }));
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`=======================================================`);
  console.log(`🚀 ENG401 Web Servisi Başlatıldı!`);
  console.log(`📡 Dinlenen Adres: http://localhost:${PORT}`);
  console.log(`📌 Hesaplama URL : http://localhost:${PORT}/api/calculate`);
  console.log(`💡 Mobil cihazdan 7 input gönderilecek, 1 output dönecek.`);
  console.log(`=======================================================`);
});

