from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.textinput import TextInput
from kivy.uix.button import Button
from kivy.uix.label import Label
from vault_core import SecureVault

class SecureVaultApp(App):
    def build(self):
        self.vault = SecureVault()
        self.encrypted_cache = {}

        layout = BoxLayout(orientation='vertical', padding=20, spacing=15)

        self.input_data = TextInput(text='{"destination": "mobile_node", "payload": "secret"}', size_hint_y=None, height=100)
        layout.add_widget(self.input_data)

        btn_encrypt = Button(text='Encrypt Payload', size_hint_y=None, height=50)
        btn_encrypt.bind(on_press=self.encrypt_action)
        layout.add_widget(btn_encrypt)

        self.output_label = Label(text='Status: Idle', halign='center')
        layout.add_widget(self.output_label)

        btn_decrypt = Button(text='Decrypt Payload', size_hint_y=None, height=50)
        btn_decrypt.bind(on_press=self.decrypt_action)
        layout.add_widget(btn_decrypt)

        return layout

    def encrypt_action(self, instance):
        try:
            import json
            data = json.loads(self.input_data.text)
            self.encrypted_cache = self.vault.encrypt_payload(data)
            self.output_label.text = f"Encrypted:\n{self.encrypted_cache['ciphertext'][:32]}..."
        except Exception as e:
            self.output_label.text = f"Error: {str(e)}"

    def decrypt_action(self, instance):
        try:
            decrypted = self.vault.decrypt_payload(self.encrypted_cache)
            self.output_label.text = f"Decrypted:\n{str(decrypted)}"
        except Exception as e:
            self.output_label.text = f"Decrypt Error: {str(e)}"

if __name__ == '__main__':
    SecureVaultApp().run()
