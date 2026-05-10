const api = require("@raycast/api");
const React = require("react");
const { spawnSync } = require("child_process");
const { jsx, jsxs } = require("react/jsx-runtime");

const TYPES = [
  { id: "iban", title: "IBAN" },
  { id: "account", title: "Account Number" },
  { id: "phone", title: "Phone Number" },
  { id: "address", title: "Address" },
];

const COUNTRIES = [
  { id: "sy", title: "Syria" },
  { id: "eg", title: "Egypt" },
  { id: "bd", title: "Bangladesh" },
  { id: "ng", title: "Nigeria" },
  { id: "pk", title: "Pakistan" },
];

function randDigits(n) {
  let result = "";
  while (result.length < n) {
    result += Math.floor(Math.random() * 10).toString();
  }
  return result.slice(0, n);
}

function randRange(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function pick(items) {
  return items[Math.floor(Math.random() * items.length)];
}

// IBAN check digits via mod-97-10 (ISO 13616).
// Country letters map to digits: A=10, B=11, ..., Z=35.
function ibanCheckDigits(countryCode, bban) {
  const rearranged = bban + countryCode + "00";
  const numeric = rearranged
    .split("")
    .map((c) => {
      const code = c.charCodeAt(0);
      if (code >= 48 && code <= 57) return c;
      return (code - 55).toString();
    })
    .join("");
  const remainder = Number(BigInt(numeric) % 97n);
  return (98 - remainder).toString().padStart(2, "0");
}

function generateIban(country) {
  switch (country) {
    case "sy":
      return `SY${randDigits(22)}`;
    case "eg": {
      const bank = String(randRange(1, 99)).padStart(4, "0");
      const account = randDigits(21);
      const bban = bank + account;
      return `EG${ibanCheckDigits("EG", bban)}${bban}`;
    }
    case "bd":
      return `BD${randDigits(16)}`;
    case "ng": {
      const banks = ["044", "058", "011", "033", "032", "030", "050", "070"];
      return `${pick(banks)}${randDigits(7)}`;
    }
    case "pk": {
      const banks = ["ALFH", "HABB", "MUCB", "NBPA", "SCBL", "UNIL", "BAHL", "MEZN"];
      return `PK${randDigits(2)}${pick(banks)}${randDigits(16)}`;
    }
    default:
      throw new Error(`Unsupported country: ${country}`);
  }
}

function generateAccountNumber(country) {
  switch (country) {
    case "sy":
      return randDigits(12);
    case "eg":
      return randDigits(16);
    case "bd":
      return randDigits(13);
    case "ng":
      return randDigits(10);
    case "pk":
      return randDigits(16);
    default:
      throw new Error(`Unsupported country: ${country}`);
  }
}

function generatePhone(country) {
  switch (country) {
    case "sy":
      return `+963 9${randDigits(2)} ${randDigits(3)} ${randDigits(3)}`;
    case "eg": {
      const prefix = pick(["0", "1", "2", "5"]);
      return `+20 1${prefix} ${randDigits(4)} ${randDigits(4)}`;
    }
    case "bd": {
      const prefix = pick(["3", "4", "5", "6", "7", "8", "9"]);
      return `+880 1${prefix}${randDigits(2)} ${randDigits(6)}`;
    }
    case "ng": {
      const prefix = pick(["03", "06", "07", "08", "09", "10", "13", "14"]);
      return `+234 8${prefix} ${randDigits(3)} ${randDigits(4)}`;
    }
    case "pk": {
      const prefix = pick([
        "00", "01", "02", "03", "04", "05", "06", "07", "08", "09",
        "10", "11", "12", "13", "14", "15", "16", "17", "18", "19",
        "20", "21", "22", "23", "24", "25", "26", "27", "28", "29",
        "30", "31", "32", "33", "34", "35", "36", "37", "38", "39",
        "40", "41", "42", "43", "44", "45", "46", "47", "48", "49",
      ]);
      return `+92 3${prefix} ${randDigits(7)}`;
    }
    default:
      throw new Error(`Unsupported country: ${country}`);
  }
}

function generateAddress(country) {
  const number = randRange(1, 250);

  switch (country) {
    case "sy": {
      const streets = ["Al-Thawra Street", "Baghdad Street", "Straight Street", "Al-Hamidiyah", "Maysaloun Street", "Port Said Street", "Al-Jalaa Street", "Ibrahim Hanano Street"];
      const cities = ["Damascus", "Aleppo", "Homs", "Latakia", "Hama", "Tartus", "Deir ez-Zor", "Raqqa"];
      const areas = ["Abu Rummaneh", "Malki", "Mezzeh", "Sha'lan", "Baramkeh", "Muhajirin", "Bab Touma", "Kafr Souseh"];
      return `${number} ${pick(streets)}, ${pick(areas)}, ${pick(cities)}, Syria`;
    }
    case "eg": {
      const streets = ["Tahrir Street", "Corniche El Nil", "26th of July Street", "Salah Salem Road", "El Merghany Street", "Ahmed Orabi Street", "Ramsis Street", "El Haram Street"];
      const cities = ["Cairo", "Alexandria", "Giza", "Luxor", "Aswan", "Mansoura", "Tanta", "Port Said"];
      const areas = ["Zamalek", "Maadi", "Heliopolis", "Dokki", "Mohandessin", "Nasr City", "Garden City", "Downtown"];
      return `${number} ${pick(streets)}, ${pick(areas)}, ${pick(cities)}, Egypt`;
    }
    case "bd": {
      const streets = ["Mirpur Road", "Dhanmondi Road", "Gulshan Avenue", "Satmasjid Road", "Green Road", "Elephant Road", "Banani Road", "Mohakhali Road"];
      const cities = ["Dhaka", "Chittagong", "Sylhet", "Rajshahi", "Khulna", "Rangpur", "Comilla", "Gazipur"];
      const areas = ["Dhanmondi", "Gulshan", "Banani", "Uttara", "Mirpur", "Mohammadpur", "Motijheel", "Tejgaon"];
      return `${number} ${pick(streets)}, ${pick(areas)}, ${pick(cities)}, Bangladesh`;
    }
    case "ng": {
      const streets = ["Broad Street", "Marina Road", "Awolowo Road", "Adeola Odeku Street", "Ademola Adetokunbo", "Allen Avenue", "Ozumba Mbadiwe", "Tafawa Balewa Square"];
      const cities = ["Lagos", "Abuja", "Kano", "Ibadan", "Port Harcourt", "Benin City", "Kaduna", "Enugu"];
      const areas = ["Victoria Island", "Ikoyi", "Lekki", "Ikeja", "Surulere", "Yaba", "Ajah", "Wuse"];
      return `${number} ${pick(streets)}, ${pick(areas)}, ${pick(cities)}, Nigeria`;
    }
    case "pk": {
      const streets = ["Mall Road", "Jinnah Avenue", "Shahrah-e-Faisal", "GT Road", "Murree Road", "Tariq Road", "University Road", "Clifton Road"];
      const cities = ["Karachi", "Lahore", "Islamabad", "Rawalpindi", "Faisalabad", "Peshawar", "Multan", "Quetta"];
      const areas = ["Gulberg", "DHA", "Clifton", "F-7", "G-9", "Blue Area", "Saddar", "Model Town"];
      return `${number} ${pick(streets)}, ${pick(areas)}, ${pick(cities)}, Pakistan`;
    }
    default:
      throw new Error(`Unsupported country: ${country}`);
  }
}

function generateValue(type, country) {
  switch (type) {
    case "iban":
      return generateIban(country);
    case "account":
      return generateAccountNumber(country);
    case "phone":
      return generatePhone(country);
    case "address":
      return generateAddress(country);
    default:
      throw new Error(`Unsupported type: ${type}`);
  }
}

function countryLabel(id) {
  return COUNTRIES.find((country) => country.id === id)?.title ?? id;
}

function typeLabel(id) {
  return TYPES.find((type) => type.id === id)?.title ?? id;
}

function runCommand(command, args, options = {}) {
  const result = spawnSync(command, args, { encoding: "utf8", ...options });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    const stderr = result.stderr?.trim();
    throw new Error(stderr || `${command} exited with status ${result.status}`);
  }
  return result.stdout ?? "";
}

function copyToSimulatorClipboard(value) {
  runCommand("xcrun", ["simctl", "pbcopy", "booted"], { input: value });
  const pasted = runCommand("xcrun", ["simctl", "pbpaste", "booted"]);
  if (pasted !== value) {
    throw new Error("Simulator clipboard verification failed");
  }
}

function Command() {
  const [type, setType] = React.useState("iban");
  const [country, setCountry] = React.useState("sy");
  const [isLoading, setIsLoading] = React.useState(false);

  async function handleSubmit() {
    try {
      setIsLoading(true);
      const value = generateValue(type, country);
      copyToSimulatorClipboard(value);
      await api.Clipboard.copy(value);
      await api.showHUD(`Copied ${typeLabel(type)} for ${countryLabel(country)} to Simulator`);
      await api.popToRoot({ clearSearchBar: true });
      await api.closeMainWindow({ clearRootSearch: true, popToRootType: "default" });
    } catch (error) {
      await api.showToast({
        style: api.Toast.Style.Failure,
        title: "Failed to generate test data",
        message: error instanceof Error ? error.message : String(error),
      });
    } finally {
      setIsLoading(false);
    }
  }

  return jsxs(api.Form, {
    isLoading,
    actions: jsx(api.ActionPanel, {
      children: jsx(api.Action.SubmitForm, {
        title: "Generate and Copy to Simulator",
        onSubmit: handleSubmit,
      }),
    }),
    children: [
      jsx(api.Form.Description, {
        text: "Generate fake test data and copy it straight to the booted iOS Simulator clipboard.",
      }),
      jsxs(api.Form.Dropdown, {
        id: "type",
        title: "Type",
        value: type,
        onChange: setType,
        children: TYPES.map((item) =>
          jsx(api.Form.Dropdown.Item, {
            value: item.id,
            title: item.title,
          }, item.id),
        ),
      }),
      jsxs(api.Form.Dropdown, {
        id: "country",
        title: "Country",
        value: country,
        onChange: setCountry,
        children: COUNTRIES.map((item) =>
          jsx(api.Form.Dropdown.Item, {
            value: item.id,
            title: item.title,
          }, item.id),
        ),
      }),
    ],
  });
}

module.exports = { default: Command };
