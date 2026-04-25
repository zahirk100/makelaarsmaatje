/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          green: "#1F3D2B",
          gold: "#C8821A",
          goldLight: "#E8C07D",
          cream: "#FAF6EE",
          creamDark: "#F2ECDE",
          border: "#E5DFD3",
          borderLight: "#F5F1E9",
          borderDark: "#D9CFB8",
        },
      },
      fontFamily: {
        display: ["Fraunces", "Georgia", "serif"],
        sans: ["Inter", "system-ui", "sans-serif"],
      },
    },
  },
  plugins: [],
};
