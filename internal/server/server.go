package server

import (
	"context"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"

	"rfid-tool-rpi/internal/config"
	"rfid-tool-rpi/internal/rfid"

	"github.com/gorilla/mux"
	"github.com/gorilla/websocket"
)

// WebServer represents the web server
type WebServer struct {
	server   *http.Server
	reader   *rfid.Reader
	config   *config.Config
	upgrader websocket.Upgrader
}

// CardData represents card data for JSON responses
type CardData struct {
	UID    string            `json:"uid"`
	Type   string            `json:"type"`
	Size   int               `json:"size"`
	Blocks int               `json:"blocks"`
	Data   map[string]string `json:"data,omitempty"`
}

// APIResponse represents a standard API response
type APIResponse struct {
	Success bool        `json:"success"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

// WriteRequest represents a write request
type WriteRequest struct {
	Block int    `json:"block"`
	Data  string `json:"data"`
}

// NewWebServer creates a new web server instance
func NewWebServer(port string, reader *rfid.Reader, cfg *config.Config) *WebServer {
	return &WebServer{
		reader: reader,
		config: cfg,
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				return true // Allow all origins for development
			},
		},
	}
}

// Start starts the web server
func (ws *WebServer) Start() error {
	router := mux.NewRouter()

	// Static files
	router.PathPrefix("/static/").Handler(http.StripPrefix("/static/", http.FileServer(http.Dir(ws.config.Web.StaticDir))))

	// API routes
	api := router.PathPrefix("/api").Subrouter()
	api.HandleFunc("/scan", ws.handleScan).Methods("POST")
	api.HandleFunc("/read", ws.handleRead).Methods("POST")
	api.HandleFunc("/read/{block}", ws.handleReadBlock).Methods("GET")
	api.HandleFunc("/write", ws.handleWrite).Methods("POST")
	api.HandleFunc("/card/info", ws.handleCardInfo).Methods("GET")
	api.HandleFunc("/websocket", ws.handleWebSocket)

	// Web pages
	router.HandleFunc("/", ws.handleIndex)

	// CORS middleware
	router.Use(ws.corsMiddleware)

	ws.server = &http.Server{
		Addr:         ":" + strings.TrimPrefix(ws.server.Addr, ":"),
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
	}

	log.Printf("Starting web server on port %s", ws.server.Addr)
	return ws.server.ListenAndServe()
}

// Stop stops the web server
func (ws *WebServer) Stop() error {
	if ws.server != nil {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		return ws.server.Shutdown(ctx)
	}
	return nil
}

// corsMiddleware adds CORS headers
func (ws *WebServer) corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

// handleIndex serves the main page
func (ws *WebServer) handleIndex(w http.ResponseWriter, r *http.Request) {
	tmpl := `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RFID Tool</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .card-info {
            background: #e8f4f8;
            padding: 20px;
            border-radius: 6px;
            margin: 20px 0;
        }
        .button {
            background: #007cba;
            color: white;
            padding: 12px 24px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            margin: 5px;
            font-size: 16px;
        }
        .button:hover {
            background: #005a8a;
        }
        .button:disabled {
            background: #ccc;
            cursor: not-allowed;
        }
        .error {
            background: #ffe6e6;
            color: #d00;
            padding: 10px;
            border-radius: 4px;
            margin: 10px 0;
        }
        .success {
            background: #e6ffe6;
            color: #0a0;
            padding: 10px;
            border-radius: 4px;
            margin: 10px 0;
        }
        .data-table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        .data-table th, .data-table td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        .data-table th {
            background: #f2f2f2;
        }
        .hex-input {
            width: 300px;
            font-family: monospace;
            padding: 8px;
            border: 1px solid #ddd;
            border-radius: 4px;
        }
        .status {
            padding: 10px;
            border-radius: 4px;
            margin: 10px 0;
            font-weight: bold;
        }
        .status.connected {
            background: #e6ffe6;
            color: #0a0;
        }
        .status.disconnected {
            background: #ffe6e6;
            color: #d00;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>RFID Reader/Writer Tool</h1>

        <div id="status" class="status disconnected">Disconnected</div>

        <div class="controls">
            <button id="scanBtn" class="button">Scan for Card</button>
            <button id="readBtn" class="button" disabled>Read All Data</button>
            <button id="clearBtn" class="button">Clear Display</button>
        </div>

        <div id="cardInfo" class="card-info" style="display:none;">
            <h3>Card Information</h3>
            <p><strong>UID:</strong> <span id="cardUID"></span></p>
            <p><strong>Type:</strong> <span id="cardType"></span></p>
            <p><strong>Size:</strong> <span id="cardSize"></span> bytes</p>
            <p><strong>Blocks:</strong> <span id="cardBlocks"></span></p>
        </div>

        <div id="dataSection" style="display:none;">
            <h3>Card Data</h3>
            <table class="data-table" id="dataTable">
                <thead>
                    <tr>
                        <th>Block</th>
                        <th>Data (Hex)</th>
                        <th>Data (ASCII)</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody id="dataTableBody">
                </tbody>
            </table>
        </div>

        <div id="writeSection" style="display:none;">
            <h3>Write Data</h3>
            <div>
                <label>Block: <input type="number" id="writeBlock" min="0" max="63" value="1"></label>
            </div>
            <div style="margin: 10px 0;">
                <label>Data (32 hex chars): <input type="text" id="writeData" class="hex-input" maxlength="32" placeholder="00112233445566778899AABBCCDDEEFF"></label>
            </div>
            <button id="writeBtn" class="button">Write Block</button>
        </div>

        <div id="messages"></div>
    </div>

    <script>
        let ws;
        let currentCard = null;

        function connectWebSocket() {
            const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            ws = new WebSocket(protocol + '//' + window.location.host + '/api/websocket');

            ws.onopen = function() {
                updateStatus('Connected', true);
            };

            ws.onmessage = function(event) {
                const data = JSON.parse(event.data);
                handleWebSocketMessage(data);
            };

            ws.onclose = function() {
                updateStatus('Disconnected', false);
                setTimeout(connectWebSocket, 3000);
            };

            ws.onerror = function(error) {
                console.error('WebSocket error:', error);
                updateStatus('Connection Error', false);
            };
        }

        function updateStatus(message, connected) {
            const statusEl = document.getElementById('status');
            statusEl.textContent = message;
            statusEl.className = 'status ' + (connected ? 'connected' : 'disconnected');
        }

        function handleWebSocketMessage(data) {
            if (data.type === 'card_detected') {
                currentCard = data.card;
                displayCardInfo(data.card);
                showMessage('Card detected: ' + data.card.uid, 'success');
            } else if (data.type === 'card_removed') {
                currentCard = null;
                hideCardInfo();
                showMessage('Card removed', 'success');
            }
        }

        function showMessage(message, type) {
            const messagesEl = document.getElementById('messages');
            const messageEl = document.createElement('div');
            messageEl.className = type;
            messageEl.textContent = message;
            messagesEl.appendChild(messageEl);

            setTimeout(() => {
                messagesEl.removeChild(messageEl);
            }, 5000);
        }

        function displayCardInfo(card) {
            document.getElementById('cardUID').textContent = card.uid;
            document.getElementById('cardType').textContent = card.type;
            document.getElementById('cardSize').textContent = card.size;
            document.getElementById('cardBlocks').textContent = card.blocks;
            document.getElementById('cardInfo').style.display = 'block';
            document.getElementById('writeSection').style.display = 'block';
            document.getElementById('readBtn').disabled = false;
        }

        function hideCardInfo() {
            document.getElementById('cardInfo').style.display = 'none';
            document.getElementById('dataSection').style.display = 'none';
            document.getElementById('writeSection').style.display = 'none';
            document.getElementById('readBtn').disabled = true;
        }

        function displayCardData(data) {
            const tbody = document.getElementById('dataTableBody');
            tbody.innerHTML = '';

            Object.keys(data).sort((a, b) => parseInt(a) - parseInt(b)).forEach(block => {
                const row = tbody.insertRow();
                const hexData = data[block];
                const asciiData = hexToAscii(hexData);

                row.insertCell(0).textContent = block;
                row.insertCell(1).textContent = hexData;
                row.insertCell(2).textContent = asciiData;

                const actionsCell = row.insertCell(3);
                const editBtn = document.createElement('button');
                editBtn.textContent = 'Edit';
                editBtn.className = 'button';
                editBtn.onclick = () => editBlock(block, hexData);
                actionsCell.appendChild(editBtn);
            });

            document.getElementById('dataSection').style.display = 'block';
        }

        function hexToAscii(hex) {
            let ascii = '';
            for (let i = 0; i < hex.length; i += 2) {
                const charCode = parseInt(hex.substr(i, 2), 16);
                ascii += (charCode >= 32 && charCode <= 126) ? String.fromCharCode(charCode) : '.';
            }
            return ascii;
        }

        function editBlock(block, currentData) {
            document.getElementById('writeBlock').value = block;
            document.getElementById('writeData').value = currentData;
            document.getElementById('writeData').focus();
        }

        // Event listeners
        document.getElementById('scanBtn').addEventListener('click', function() {
            fetch('/api/scan', { method: 'POST' })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        currentCard = data.data;
                        displayCardInfo(data.data);
                        showMessage('Card scanned successfully', 'success');
                    } else {
                        showMessage(data.message, 'error');
                    }
                })
                .catch(error => {
                    showMessage('Error scanning card: ' + error.message, 'error');
                });
        });

        document.getElementById('readBtn').addEventListener('click', function() {
            if (!currentCard) {
                showMessage('No card selected', 'error');
                return;
            }

            fetch('/api/read', { method: 'POST' })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        displayCardData(data.data.data);
                        showMessage('Card data read successfully', 'success');
                    } else {
                        showMessage(data.message, 'error');
                    }
                })
                .catch(error => {
                    showMessage('Error reading card: ' + error.message, 'error');
                });
        });

        document.getElementById('writeBtn').addEventListener('click', function() {
            const block = parseInt(document.getElementById('writeBlock').value);
            const data = document.getElementById('writeData').value;

            if (!currentCard) {
                showMessage('No card selected', 'error');
                return;
            }

            if (data.length !== 32 || !/^[0-9A-Fa-f]+$/.test(data)) {
                showMessage('Data must be exactly 32 hexadecimal characters', 'error');
                return;
            }

            fetch('/api/write', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    block: block,
                    data: data
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    showMessage('Block ' + block + ' written successfully', 'success');
                } else {
                    showMessage(data.message, 'error');
                }
            })
            .catch(error => {
                showMessage('Error writing block: ' + error.message, 'error');
            });
        });

        document.getElementById('clearBtn').addEventListener('click', function() {
            hideCardInfo();
            document.getElementById('messages').innerHTML = '';
            currentCard = null;
        });

        // Initialize WebSocket connection
        connectWebSocket();
    </script>
</body>
</html>`

	w.Header().Set("Content-Type", "text/html")
	w.Write([]byte(tmpl))
}

// handleScan handles card scanning requests
func (ws *WebServer) handleScan(w http.ResponseWriter, r *http.Request) {
	card, err := ws.reader.ScanForCard()
	if err != nil {
		ws.writeJSON(w, APIResponse{
			Success: false,
			Message: fmt.Sprintf("Failed to scan card: %v", err),
		})
		return
	}

	cardData := CardData{
		UID:    hex.EncodeToString(card.UID),
		Type:   string(card.Type),
		Size:   card.Size,
		Blocks: card.Blocks,
	}

	ws.writeJSON(w, APIResponse{
		Success: true,
		Message: "Card scanned successfully",
		Data:    cardData,
	})
}

// handleRead handles reading all card data
func (ws *WebServer) handleRead(w http.ResponseWriter, r *http.Request) {
	if ws.reader.GetLastCard() == nil {
		ws.writeJSON(w, APIResponse{
			Success: false,
			Message: "No card selected",
		})
		return
	}

	data, err := ws.reader.ReadCard()
	if err != nil {
		ws.writeJSON(w, APIResponse{
			Success: false,
			Message: fmt.Sprintf("Failed to read card: %v", err),
		})
		return
	}

	// Convert byte arrays to hex strings
	hexData := make(map[string]string)
	for block, blockData := range data {
		hexData[strconv.Itoa(block)] = hex.EncodeToString(blockData)
	}

	card := ws.reader.GetLastCard()
	cardData := CardData{
		UID:    hex.EncodeToString(card.UID),
		Type:   string(card.Type),
		Size:   card.Size,
		Blocks: card.Blocks,
		Data:   hexData,
	}

	ws.writeJSON(w, APIResponse{
		Success: true,
		Message: "Card data read successfully",
		Data:    cardData,
	})
}

// handleReadBlock handles reading a specific block
func (ws *WebServer) handleReadBlock(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	blockStr, ok := vars["block"]
	if !ok {
		ws.writeJSON(w, APIResponse{
			Success: false,
			Message: "Block parameter required",
		})
		return
	}

	block, err := strconv.Atoi(blockStr)
	if err != nil {
		ws.writeJSON(w, APIResponse{
			Success: false,
			Message: "Invalid block number",
		})
		return
	}

	if ws.reader.GetLastCard() == nil {
		ws.writeJSON(w, APIResponse{
			Success: false,
			Message: "No card selected",
		})
		return
	}

	data, err := ws.reader.ReadBlock(block)
	if err != nil {
		ws.writeJSON(w, APIResponse{
			Success: false,
			Message: fmt.Sprintf("Failed to read block %d: %v", block, err),
		})
		return
	}

	ws.writeJSON(w, APIResponse{
		Success: true,
		Message: fmt.Sprintf("Block %d read successfully", block),
		Data:    hex.EncodeToString(data),
	})
}

// handleWrite handles writing data to a block
func (ws *WebServer) handleWrite(w http.ResponseWriter, r *http.Request) {
	var req WriteRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		ws.writeJSON(w, APIResponse{
			Success: false,
			Message: "Invalid request format",
		})
		return
	}

	if ws.reader.GetLastCard() == nil {
		ws.writeJSON(w, APIResponse{
			Success: false,
			Message: "No card selected",
		})
		return
	}

	// Convert hex string to bytes
	data, err := hex.DecodeString(req.Data)
	if err != nil {
		ws.writeJSON(w, APIResponse{
			Success: false,
			Message: "Invalid hex data",
		})
		return
	}

	if len(data) != 16 {
		ws.writeJSON(w, APIResponse{
			Success: false,
			Message: "Data must be exactly 16 bytes (32 hex characters)",
		})
		return
	}

	if err := ws.reader.WriteBlock(req.Block, data); err != nil {
		ws.writeJSON(w, APIResponse{
			Success: false,
			Message: fmt.Sprintf("Failed to write block %d: %v", req.Block, err),
		})
		return
	}

	ws.writeJSON(w, APIResponse{
		Success: true,
		Message: fmt.Sprintf("Block %d written successfully", req.Block),
	})
}

// handleCardInfo handles getting current card information
func (ws *WebServer) handleCardInfo(w http.ResponseWriter, r *http.Request) {
	card := ws.reader.GetLastCard()
	if card == nil {
		ws.writeJSON(w, APIResponse{
			Success: false,
			Message: "No card selected",
		})
		return
	}

	cardData := CardData{
		UID:    hex.EncodeToString(card.UID),
		Type:   string(card.Type),
		Size:   card.Size,
		Blocks: card.Blocks,
	}

	ws.writeJSON(w, APIResponse{
		Success: true,
		Data:    cardData,
	})
}

// handleWebSocket handles WebSocket connections for real-time updates
func (ws *WebServer) handleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := ws.upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("WebSocket upgrade error: %v", err)
		return
	}
	defer conn.Close()

	log.Println("WebSocket client connected")

	// Send periodic card detection updates
	ticker := time.NewTicker(1 * time.Second)
	defer ticker.Stop()

	var lastCardPresent bool

	for {
		select {
		case <-ticker.C:
			cardPresent := ws.reader.IsCardPresent()

			if cardPresent && !lastCardPresent {
				// Card detected
				if card := ws.reader.GetLastCard(); card != nil {
					cardData := CardData{
						UID:    hex.EncodeToString(card.UID),
						Type:   string(card.Type),
						Size:   card.Size,
						Blocks: card.Blocks,
					}

					message := map[string]interface{}{
						"type": "card_detected",
						"card": cardData,
					}

					if err := conn.WriteJSON(message); err != nil {
						log.Printf("WebSocket write error: %v", err)
						return
					}
				}
			} else if !cardPresent && lastCardPresent {
				// Card removed
				message := map[string]interface{}{
					"type": "card_removed",
				}

				if err := conn.WriteJSON(message); err != nil {
					log.Printf("WebSocket write error: %v", err)
					return
				}
			}

			lastCardPresent = cardPresent

		default:
			// Check if connection is still alive
			if err := conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

// writeJSON writes a JSON response
func (ws *WebServer) writeJSON(w http.ResponseWriter, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(data)
}
