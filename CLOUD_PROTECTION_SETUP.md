
# ☁️ Setting Up Automatic Cloud Billing Protection

The code now includes a `stop_billing_emergency` function. For this to work "automatically in the cloud", you need to connect it to your Google Cloud Billing.

### 1. Create a Topic
1. Go to **Google Cloud Console** > **Pub/Sub** > **Topics**.
2. Create a Topic named `billing-alerts`.

### 2. Set Up Budget Alert
1. Go to **Billing** > **Budgets & alerts**.
2. Click **Create Budget**.
3. **Scope**: Select your project.
4. **Amount**: Set your monthly limit (e.g., $1.00 or $0.00 if you want free tier only).
   * *Tip: Set it to $0.10 to allow for tiny overages before killing usage.*
5. **Thresholds**: 
   * Add a threshold at **50%**, **90%**, **100%**.
   * (Optional) Check "Connect a Pub/Sub topic to this budget".
   * Select the `projects/.../topics/billing-alerts` topic you created.
6. Click **Save**.

### 3. Deploy
Deploy your functions:
```bash
firebase deploy --only functions
```

### ✅ How it Works
1. When your usage hits the budget threshold (e.g., 50% of $1), GCP sends a message to `billing-alerts`.
2. The `stop_billing_emergency` function wakes up.
3. It sets `config/system_status` to `enabled: false`.
4. All other functions (Scheduler, Triggers, API) will instantly start rejecting requests.

---

### 🛡️ Secondary Protection (Code Level)
We also added a **Sharded Counter** that tracks daily invocations.
- If daily invocations > **50,000** (approx), the system will **Auto-Disable** itself.
- You can adjust `GLOBAL_DAILY_LIMIT` in `functions/sharded_counter.py`.
