# Flask API Frontend - React Application

A modern React frontend for interacting with the Flask API, containerized with Docker and deployable on Kubernetes.

## Features

✨ **Welcome Section**
- Displays a personalized welcome message from the Flask API
- Auto-loads on app startup
- Refresh button to reload the message

💬 **Personalized Greeting Section**
- Form with Name and City input fields
- Real-time API interaction
- Dynamic greeting display

🎨 **UI/UX**
- Beautiful gradient design
- Responsive layout (mobile & desktop)
- Loading states and error handling
- Smooth animations

## Prerequisites

- Node.js (v14+)
- npm or yarn
- Flask API running on `http://localhost:5000`

## Local Development Setup

### 1. Install Dependencies

```bash
cd /Users/shreyas/PycharmProjects/Devops_kubernets/frontend_app
npm install
```

### 2. Configure Environment (Optional)

The `.env` file already has the default API URL:
```
REACT_APP_API_URL=http://localhost:5000
```

To use a different API URL:
```bash
echo "REACT_APP_API_URL=https://your-api-url.com" > .env
```

### 3. Start Development Server

```bash
npm start
```

The application will open at `http://localhost:3000`

### 4. Build for Production

```bash
npm run build
```

Output will be in the `build/` directory.

## Project Structure

```
frontend_app/
├── public/
│   └── index.html              # HTML template
├── src/
│   ├── components/
│   │   ├── WelcomeSection.js   # Welcome message component
│   │   └── GreetingForm.js     # Greeting form component
│   ├── styles/
│   │   ├── WelcomeSection.css
│   │   └── GreetingForm.css
│   ├── services/
│   │   └── apiService.js       # API client
│   ├── App.js                  # Main app component
│   ├── App.css
│   ├── index.js                # Entry point
│   └── index.css               # Global styles
├── package.json                # Dependencies
├── .env                        # Environment variables
└── .gitignore
```

## API Endpoints

The frontend calls the following Flask API endpoints:

### GET /
Returns a welcome message

**Response:**
```json
{
  "message": "Good morning from Shreyas K N. Great job!"
}
```

### GET /greeting
Returns a personalized greeting

**Parameters:**
- `Name` (string): Person's name
- `City` (string): Person's city

**Response:**
```json
{
  "Greeting": "Hello Shreyas",
  "Message": "How are things at Bangalore?"
}
```

## Quick Start

```bash
# Install dependencies
npm install

# Start development server
npm start

# Build for production
npm run build
```

The app will be available at `http://localhost:3000`

## Docker Deployment

```bash
docker build -t flask-react-frontend:latest .
docker run -p 3000:3000 flask-react-frontend:latest
```

## Troubleshooting

### API Connection Issues
1. Verify Flask API is running on port 5000
2. Check browser console (F12) for CORS errors
3. Ensure FLASK_CORS is configured in Flask app

### Build Errors
```bash
npm cache clean --force
rm -rf node_modules package-lock.json
npm install
```

## License

MIT

