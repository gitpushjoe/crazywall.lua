from caesar_cipher import caesar_cipher_encode, caesar_cipher_decode

if __name__ == "__main__":
    text = "Hello, world!"
    print(text)
    text = caesar_cipher_encode(text, 42)
    print(text)
    text = caesar_cipher_decode(text, 42)
    print(text)