import numpy as np
from pydub import AudioSegment
import argparse
import sys
import os

def convert(input_file, output_file, rate, boost):
    try:
        print(f"--- Elaborazione: {input_file} ---")
        # Caricamento e conversione in Mono
        audio = AudioSegment.from_file(input_file).set_channels(1)
        audio = audio.set_frame_rate(rate)
        
        # Conversione in array numpy (float per precisione)
        samples = np.array(audio.get_array_of_samples()).astype(np.float32)
        
        # 1. Normalizzazione (Peak a 0dB)
        samples -= np.mean(samples)
        max_val = np.max(np.abs(samples))
        if max_val > 0:
            samples = samples / max_val
            
        # 2. Conversione a 6 bit (0-63)
        samples_6bit = ((samples + 1) / 2 * 63).astype(np.uint8)
        
        # 3. Applicazione dello Shift per il volume (se richiesto)
        if boost:
            # Allinea i 6 bit ai bit 2-7 del registro MO6
            final_samples = (samples_6bit << 2).astype(np.uint8)
            mode = "BOOST (6-bit shifted to MSB)"
        else:
            final_samples = samples_6bit
            mode = "NORMAL (6-bit LSB)"
            
        # Scrittura rapida del binario
        with open(output_file, "wb") as f:
            f.write(final_samples.tobytes())
            
        print(f"Successo!")
        print(f"Frequenza: {rate} Hz")
        print(f"Modalità:  {mode}")
        print(f"Output:    {output_file} ({os.path.getsize(output_file)} byte)")

    except Exception as e:
        print(f"Errore: {e}")
        sys.exit(1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Convertitore Audio MP3 to 6-bit RAW per Thomson MO6')
    
    parser.add_argument('input', help='File audio di input (mp3, wav, etc.)')
    parser.add_argument('output', help='Nome del file .bin in uscita')
    parser.add_argument('-r', '--rate', type=int, default=8000, help='Sample rate (default: 8000)')
    parser.add_argument('--no-boost', action='store_false', dest='boost', help='Disattiva lo shift a sinistra dei bit')
    parser.set_defaults(boost=True)

    args = parser.parse_args()
    convert(args.input, args.output, args.rate, args.boost)