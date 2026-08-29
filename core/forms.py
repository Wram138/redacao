from django import forms
from .models import Materia, Pauta

class MateriaForm(forms.ModelForm):
    class Meta:
        model = Materia
        fields = ['texto']
        widgets = {
            'texto': forms.Textarea(attrs={'class': 'form-control', 'rows': 15, 'placeholder': 'Escreva sua matéria aqui...'}),
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