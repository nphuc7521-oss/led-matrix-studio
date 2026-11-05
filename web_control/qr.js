// Minimal Standard QR Code Generator (Version 2, 25x25, Byte Mode, EC Level L)
// Generates 100% standard QR code readable by any iOS Camera / Android Camera.
(function(window) {
    // GF(256) math
    var EXP = new Uint8Array(512);
    var LOG = new Uint8Array(256);
    var x = 1;
    for (var i = 0; i < 255; i++) {
        EXP[i] = x;
        EXP[i + 255] = x;
        LOG[x] = i;
        x = (x << 1) ^ (x >= 128 ? 0x11d : 0);
    }

    function gfMul(x, y) {
        if (x === 0 || y === 0) return 0;
        return EXP[LOG[x] + LOG[y]];
    }

    // RS generator polynomial for 10 error correction codewords (Version 2-L)
    // Poly: x^10 + 216 x^9 + 194 x^8 + 159 x^7 + 111 x^6 + 199 x^5 + 94 x^4 + 95 x^3 + 113 x^2 + 157 x + 193
    var RS_POLY_10 = [1, 216, 194, 159, 111, 199, 94, 95, 113, 157, 193];

    function calcEcc(data, numEcc) {
        var res = new Uint8Array(numEcc);
        for (var i = 0; i < data.length; i++) {
            var factor = data[i] ^ res[0];
            for (var j = 0; j < numEcc - 1; j++) {
                res[j] = res[j + 1] ^ gfMul(RS_POLY_10[j + 1], factor);
            }
            res[numEcc - 1] = gfMul(RS_POLY_10[numEcc], factor);
        }
        return res;
    }

    function createQR(text) {
        // Version 2-L capacity: 34 data codewords, 10 EC codewords, total 44 codewords.
        var data = new Uint8Array(34);
        var bits = [];

        function pushBits(val, len) {
            for (var i = len - 1; i >= 0; i--) bits.push((val >> i) & 1);
        }

        // Mode: 8-bit byte (0100)
        pushBits(4, 4);
        var len = Math.min(text.length, 32);
        pushBits(len, 8);
        for (var i = 0; i < len; i++) {
            pushBits(text.charCodeAt(i), 8);
        }
        // Terminator
        pushBits(0, 4);
        while (bits.length % 8 !== 0) bits.push(0);

        var bytePos = 0;
        for (var i = 0; i < bits.length; i += 8) {
            var b = 0;
            for (var j = 0; j < 8; j++) b = (b << 1) | bits[i + j];
            if (bytePos < 34) data[bytePos++] = b;
        }

        // Pad bytes
        var pad = 0xEC;
        while (bytePos < 34) {
            data[bytePos++] = pad;
            pad = (pad === 0xEC) ? 0x11 : 0xEC;
        }

        // Compute 10 ECC bytes
        var ecc = calcEcc(data, 10);

        // All 44 codewords
        var allCodewords = new Uint8Array(44);
        allCodewords.set(data, 0);
        allCodewords.set(ecc, 34);

        // Construct 25x25 matrix
        var n = 25;
        var matrix = [];
        var isFunction = [];
        for (var r = 0; r < n; r++) {
            matrix[r] = new Uint8Array(n);
            isFunction[r] = new Uint8Array(n);
        }

        function setFinder(r0, c0) {
            for (var r = -1; r <= 7; r++) {
                for (var c = -1; c <= 7; c++) {
                    var ro = r0 + r, co = c0 + c;
                    if (ro >= 0 && ro < n && co >= 0 && co < n) {
                        isFunction[ro][co] = 1;
                        if ((r >= 0 && r <= 6 && (c === 0 || c === 6)) ||
                            (c >= 0 && c <= 6 && (r === 0 || r === 6)) ||
                            (r >= 2 && r <= 4 && c >= 2 && c <= 4)) {
                            matrix[ro][co] = 1;
                        } else {
                            matrix[ro][co] = 0;
                        }
                    }
                }
            }
        }

        setFinder(0, 0);
        setFinder(0, n - 7);
        setFinder(n - 7, 0);

        // Alignment pattern at center (18, 18) for Version 2
        for (var r = -2; r <= 2; r++) {
            for (var c = -2; c <= 2; c++) {
                var ro = 18 + r, co = 18 + c;
                isFunction[ro][co] = 1;
                if (Math.abs(r) === 2 || Math.abs(c) === 2 || (r === 0 && c === 0)) {
                    matrix[ro][co] = 1;
                } else {
                    matrix[ro][co] = 0;
                }
            }
        }

        // Timing patterns
        for (var i = 8; i < n - 8; i++) {
            isFunction[6][i] = 1;
            matrix[6][i] = (i % 2 === 0) ? 1 : 0;
            isFunction[i][6] = 1;
            matrix[i][6] = (i % 2 === 0) ? 1 : 0;
        }

        // Dark module
        isFunction[n - 8][8] = 1;
        matrix[n - 8][8] = 1;

        // Reserve format info area
        for (var i = 0; i < 9; i++) {
            if (i < n) { isFunction[8][i] = 1; isFunction[i][8] = 1; }
        }
        for (var i = 0; i < 8; i++) {
            isFunction[8][n - 1 - i] = 1;
            isFunction[n - 1 - i][8] = 1;
        }

        // Place data bits with zigzag
        var bitIdx = 0;
        var totalBits = 44 * 8;
        var right = n - 1;
        while (right > 0) {
            if (right === 6) right--; // skip timing column
            for (var vert = 0; vert < n; vert++) {
                for (var j = 0; j < 2; j++) {
                    var c = right - j;
                    var r = ((right + 1) & 2) === 0 ? vert : (n - 1 - vert);
                    if (!isFunction[r][c]) {
                        var bitVal = 0;
                        if (bitIdx < totalBits) {
                            var byteI = bitIdx >> 3;
                            var bitI = 7 - (bitIdx & 7);
                            bitVal = (allCodewords[byteI] >> bitI) & 1;
                            bitIdx++;
                        }
                        // Mask pattern 0: (r + c) % 2 === 0
                        if ((r + c) % 2 === 0) bitVal ^= 1;
                        matrix[r][c] = bitVal;
                    }
                }
            }
            right -= 2;
        }

        // Format info: EC Level L (01), Mask 0 (000) -> 01000 = 8.
        // BCH format bits for (01000) masked with 101010000010010:
        // Raw: 010001111010110 ^ 101010000010010 = 111011111000100 (0x77C4)
        var formatBits = 0x77C4;
        for (var i = 0; i < 15; i++) {
            var b = (formatBits >> i) & 1;
            // Around top-left
            if (i < 6) matrix[8][i] = b;
            else if (i === 6) matrix[8][7] = b;
            else if (i === 7) matrix[8][8] = b;
            else if (i === 8) matrix[7][8] = b;
            else matrix[14 - i][8] = b;

            // Around right/bottom
            if (i < 8) matrix[n - 1 - i][8] = b;
            else matrix[8][n - 15 + i] = b;
        }

        return matrix;
    }

    window.drawStandardQrCode = function(canvasId, text, pixelSize) {
        var canvas = document.getElementById(canvasId);
        if (!canvas) return;
        var ctx = canvas.getContext('2d');
        var matrix = createQR(text);
        var n = matrix.length;
        var px = pixelSize || 6;
        var margin = 2 * px;
        var total = n * px + 2 * margin;

        canvas.width = total;
        canvas.height = total;
        ctx.fillStyle = '#ffffff';
        ctx.fillRect(0, 0, total, total);

        ctx.fillStyle = '#0f172a';
        for (var r = 0; r < n; r++) {
            for (var c = 0; c < n; c++) {
                if (matrix[r][c]) {
                    ctx.fillRect(margin + c * px, margin + r * px, px, px);
                }
            }
        }
    };
})(window);
