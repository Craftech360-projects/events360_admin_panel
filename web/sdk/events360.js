(function (window) {
  "use strict";

  class Events360 {
    constructor(config) {
      this.config = {
        apiKey: config.apiKey,
        organizationId: config.organizationId,
        eventId: config.eventId,
        environment: config.environment || "production",
        theme: config.theme || "light",
      };

      this.endpoints = {
        production: "https://uqnquoamrxvidtwrkdsn.supabase.co/api",
        staging: "https://staging-api.events360.com/api",
        local: "http://localhost:3003",
      };

      this.razorpay = null;
      this.isValidated = false;
    }

    //<------------------------------------------------------------------------------->//

    // Add a validation method
    async _validateApiKey() {
      if (this.isValidated) return true;

      try {
        const response = await fetch(`${this._baseUrl}/validate-key`, {
          method: "GET",
          headers: {
            "X-API-Key": this.config.apiKey,
            "Content-Type": "application/json",
          },
          mode: "cors",
          credentials: "include",
        });

        if (!response.ok) {
          throw new Error("Invalid API key");
        }

        const data = await response.json();
        // Store the organization ID from the validation response
        this.config.organizationId = data.organizationId;
        this.isValidated = true;
        return true;
      } catch (error) {
        this._showError("Authentication failed: " + error.message);
        return false;
      }
    }

    //<------------------------------------------------------------------------------->//

    // Update the init method to validate the API key first
    async init(containerId) {
      this.container = document.getElementById(containerId);
      if (!this.container) throw new Error("Container not found");

      // Show initial loading state immediately
      this._showInitialLoading();

      // Set a timeout to detect slow loading
      const timeoutPromise = new Promise((_, reject) => {
        setTimeout(() => reject(new Error("Loading timed out")), 15000);
      });

      try {
        // Race between normal initialization and timeout
        await Promise.race([this._initializeWidget(), timeoutPromise]);
      } catch (error) {
        if (error.message === "Loading timed out") {
          this._showSlowLoadingMessage();
          // Continue initialization in background
          this._initializeWidget().catch((e) => {
            this._showError(`Initialization failed: ${e.message}`);
          });
        } else {
          this._showError(`Initialization failed: ${error.message}`);
        }
      }
    }

    async _initializeWidget() {
      await this._loadStyles();

      // Validate API key before loading tickets
      const isValid = await this._validateApiKey();
      if (!isValid) return;

      await this.loadTickets(this.config.eventId);
    }

    _showInitialLoading() {
      this.container.innerHTML = `
        <div class="e360-initial-loading">
          <div class="e360-spinner"></div>
          <p>Loading ticket information...</p>
        </div>
      `;
    }

    _showSlowLoadingMessage() {
      this.container.innerHTML = `
        <div class="e360-slow-loading">
          <div class="e360-spinner"></div>
          <p>Still loading... This is taking longer than expected.</p>
          <p class="e360-slow-message">Please wait while we connect to the ticket service.</p>
        </div>
      `;
    }

    //<------------------------------------------------------------------------------->//

    // Update the loadTickets method to use the validated eventId
    async loadTickets(eventId = null) {
      try {
        this._showLoading();

        // Use the provided eventId or the one from config
        const targetEventId = eventId || this.config.eventId;
        if (!targetEventId) {
          throw new Error("No event ID provided");
        }

        // Add retry logic with exponential backoff
        let retries = 3;
        let delay = 1000; // Start with 1 second delay

        while (retries > 0) {
          try {
            const response = await fetch(
              `${this._baseUrl}/tickets/${targetEventId}`,
              {
                headers: {
                  "X-API-Key": this.config.apiKey,
                },
              }
            );

            if (!response.ok) throw new Error("Failed to load tickets");

            const tickets = await response.json();

            // Cache tickets locally for offline access
            localStorage.setItem(
              `e360_tickets_${targetEventId}`,
              JSON.stringify({
                tickets,
                timestamp: Date.now(),
              })
            );

            this._renderTickets(tickets);
            return;
          } catch (error) {
            retries--;
            if (retries === 0) throw error;

            // Wait with exponential backoff before retrying
            await new Promise((resolve) => setTimeout(resolve, delay));
            delay *= 2; // Double the delay for next retry
          }
        }
      } catch (error) {
        // Try to load from cache if available
        const cachedData = localStorage.getItem(
          `e360_tickets_${targetEventId}`
        );
        if (cachedData) {
          const { tickets, timestamp } = JSON.parse(cachedData);
          const cacheAge = Date.now() - timestamp;

          // Use cache if it's less than 1 hour old
          if (cacheAge < 3600000) {
            this._renderTickets(tickets);
            this._showWarning(
              "Using cached ticket data. Some information may be outdated."
            );
            return;
          }
        }

        this._showError(error.message);
      }
    }

    //<------------------------------------------------------------------------------->//

    async purchaseTicket(ticketId, quantity) {
      try {
        // Ensure Razorpay is loaded
        await this._initRazorpay();

        const response = await fetch(`${this._baseUrl}/purchase`, {
          method: "POST",
          headers: this._authHeaders,
          body: JSON.stringify({
            ticketId,
            quantity,
            organizationId: this.config.organizationId,
          }),
        });

        if (!response.ok) throw new Error("Payment initialization failed");

        const result = await response.json();
        return this._handleRazorpayPayment(result.paymentIntent);
      } catch (error) {
        this._showError(`Payment failed: ${error.message}`);
        throw error;
      }
    }

    //<------------------------------------------------------------------------------->//

    async _initRazorpay() {
      if (window.Razorpay) return;

      return new Promise((resolve, reject) => {
        const script = document.createElement("script");
        script.src = "https://checkout.razorpay.com/v1/checkout.js";
        script.onload = resolve;
        script.onerror = () => reject(new Error("Failed to load Razorpay SDK"));
        document.head.appendChild(script);
      });
    }

    //<------------------------------------------------------------------------------->//

    async _handleRazorpayPayment(paymentIntent) {
      return new Promise((resolve, reject) => {
        try {
          const options = {
            key: paymentIntent.key_id,
            amount: paymentIntent.amount,
            currency: paymentIntent.currency,
            order_id: paymentIntent.order_id,
            name: "Events360",
            description: paymentIntent.description,
            prefill: paymentIntent.prefill,
            theme: {
              color: this.config.theme === "dark" ? "#1a1a1a" : "#3b82f6",
            },
            handler: (response) => {
              // Store transaction ID and payment details locally before resolving
              this._saveTransactionDetails(response, paymentIntent);
              resolve(response);
            },
            modal: {
              ondismiss: () => reject(new Error("Payment cancelled")),
              // Add callback for payment failure that logs details
              escape: false, // Prevent closing with ESC key
            },
          };

          const rzp = new window.Razorpay(options);
          rzp.on("payment.failed", (response) => {
            // Log the failure details for troubleshooting
            console.error("Payment failed:", response.error);
            reject(new Error(response.error.description));
          });
          rzp.open();
        } catch (error) {
          reject(error);
        }
      });
    }

    //<------------------------------------------------------------------------------->//

    // Add method to store transaction details
    _saveTransactionDetails(response, paymentIntent) {
      // Store in localStorage for recovery if needed
      const transactionData = {
        razorpay_payment_id: response.razorpay_payment_id,
        razorpay_order_id: response.razorpay_order_id,
        razorpay_signature: response.razorpay_signature,
        amount: paymentIntent.amount,
        ticketDetails: paymentIntent.description,
        timestamp: new Date().toISOString(),
      };

      // Store in localStorage with unique key
      localStorage.setItem(
        `e360_transaction_${response.razorpay_payment_id}`,
        JSON.stringify(transactionData)
      );
    }

    //<------------------------------------------------------------------------------->//

    // Private methods
    get _baseUrl() {
      return this.endpoints[this.config.environment];
    }

    get _authHeaders() {
      return {
        "X-API-Key": this.config.apiKey,
        "X-Organization-ID": this.config.organizationId,
        "Content-Type": "application/json",
      };
    }

    //<------------------------------------------------------------------------------->//

    _renderTickets(tickets) {
      this.container.innerHTML = `
        <div class="e360-container e360-theme-${this.config.theme}">
          ${tickets
            .map(
              (ticket) => `
            <div class="e360-ticket" data-id="${ticket.id}">
              <div class="e360-header">
                <h3 class="e360-title">${ticket.name}</h3>
                <div class="e360-price">₹${ticket.price}</div>
              </div>
              
              <div class="e360-body">
                <p class="e360-description">${ticket.description}</p>
                
                <div class="e360-meta">
                  <span class="e360-stock">${ticket.available_quantity} remaining</span>
                  <span class="e360-max">Max ${ticket.max_per_user} per user</span>
                </div>
                
                <div class="e360-controls">
                  <input type="number" 
                         min="1" 
                         max="${ticket.max_per_user}" 
                         value="1"
                         class="e360-quantity">
                  <button class="e360-buy">Purchase</button>
                </div>
              </div>
            </div>
          `
            )
            .join("")}
        </div>
      `;

      this._bindEvents();
    }

    //<------------------------------------------------------------------------------->//

    _bindEvents() {
      this.container.querySelectorAll(".e360-buy").forEach((button) => {
        button.addEventListener("click", () => {
          const ticketId = button.closest(".e360-ticket").dataset.id;
          const quantity = button.previousElementSibling.value;
          this.purchaseTicket(ticketId, quantity);
        });
      });
    }

    _showLoading() {
      this.container.innerHTML = `
        <div class="e360-loading">
          <div class="e360-spinner"></div>
          Loading tickets...
        </div>
      `;
    }

    _showError(message) {
      this.container.innerHTML = `
        <div class="e360-error">
          <svg viewBox="0 0 24 24">...</svg>
          <p>${message}</p>
        </div>
      `;
    }

    async _loadStyles() {
      const style = document.createElement("link");
      style.rel = "stylesheet";
      style.href = "./styles.css";
      document.head.appendChild(style);
    }
  }

  // Export for both ES modules and global
  if (typeof module !== "undefined" && module.exports) {
    module.exports = Events360;
  } else {
    window.Events360 = Events360;
  }
})(typeof window !== "undefined" ? window : this);
