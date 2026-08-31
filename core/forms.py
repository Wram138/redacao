from django import forms
from .models import Materia, Pauta

class MateriaForm(forms.ModelForm):
    class Meta:
        model = Materia
        # Adicione os status na lista de fields
        fields = ['texto', 'status_edicao', 'status_exibicao'] 
        widgets = {
            'texto': forms.Textarea(attrs={'class': 'form-control', 'id': 'editor_materia'}),
            'status_edicao': forms.Select(attrs={'class': 'form-select'}),
            'status_exibicao': forms.Select(attrs={'class': 'form-select'}),
        }

class PautaForm(forms.ModelForm):
    class Meta:
        model = Pauta
        fields = ['retranca', 'data', 'reporter_atribuido', 'direcionamento', 'informacoes', 'status']
        widgets = {
            'retranca': forms.TextInput(attrs={'class': 'form-control'}),
            'data': forms.DateInput(attrs={'class': 'form-control', 'type': 'date'}),
            'reporter_atribuido': forms.Select(attrs={'class': 'form-select'}),
            'direcionamento': forms.Textarea(attrs={'class': 'form-control', 'id': 'editor_direcionamento'}),
            'informacoes': forms.Textarea(attrs={'class': 'form-control', 'id': 'editor_informacoes'}),
            'status': forms.Select(attrs={'class': 'form-select'}),
        }