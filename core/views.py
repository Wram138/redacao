from django.contrib.auth.decorators import login_required, permission_required
from django.shortcuts import render, get_object_or_404, redirect
from .models import Pauta, Materia, AgendaPauta
from .forms import MateriaForm, PautaForm
from django.utils import timezone

@login_required(login_url='login')
def home(request):
    """Página inicial com os atalhos do sistema"""
    return render(request, 'core/home.html')

def lista_pautas(request):
    pautas = Pauta.objects.all()
    return render(request, 'core/lista_pautas.html', {'pautas': pautas})

@login_required(login_url='login')
@permission_required('core.add_materia', raise_exception=True)
def escrever_materia(request, pauta_id):
    pauta = get_object_or_404(Pauta, id=pauta_id)
    
    # Busca a matéria caso o repórter já tenha começado a escrever
    materia = None
    if request.user.is_authenticated:
        materia = Materia.objects.filter(pauta=pauta, autor=request.user).first()
    
    if request.method == 'POST':
        form = MateriaForm(request.POST, instance=materia)
        if form.is_valid():
            nova_materia = form.save(commit=False)
            nova_materia.pauta = pauta
            nova_materia.autor = request.user # Salva em nome do usuário logado
            nova_materia.save()
            return redirect('lista_pautas')
    else:
        form = MateriaForm(instance=materia)
        
    return render(request, 'core/materia_form.html', {'form': form, 'pauta': pauta})

@login_required(login_url='login')
@permission_required('core.view_materia', raise_exception=True)
def ler_materia(request, pauta_id):
    pauta = get_object_or_404(Pauta, id=pauta_id)
    # Busca a primeira matéria vinculada a esta pauta
    materia = Materia.objects.filter(pauta=pauta).first()
    return render(request, 'core/ler_materia.html', {'pauta': pauta, 'materia': materia})

@login_required(login_url='login')
def lista_materias(request):
    usuario = request.user
    
    # Verifica se o usuário pertence ao grupo 'Repórteres'
    if usuario.groups.filter(name='Repórteres').exists():
        # Repórter vê apenas as próprias matérias
        materias = Materia.objects.filter(autor=usuario).select_related('pauta')
    else:
        # Produtores, Editores e Apresentadores vêem todas
        materias = Materia.objects.all().select_related('pauta')
        
    return render(request, 'core/lista_materias.html', {'materias': materias})

@login_required(login_url='login')
def ler_pauta(request, pauta_id):
    """Exibe os detalhes completos de uma pauta específica."""
    pauta = get_object_or_404(Pauta, id=pauta_id)
    return render(request, 'core/ler_pauta.html', {'pauta': pauta})

# Adicione a nova função no corpo do arquivo:
@login_required(login_url='login')
@permission_required('core.add_pauta', raise_exception=True)
def criar_pauta(request):
    if request.method == 'POST':
        form = PautaForm(request.POST)
        if form.is_valid():
            nova_pauta = form.save(commit=False)
            nova_pauta.criada_por = request.user
            nova_pauta.save()
            
            # Captura as listas de campos dinâmicos do HTML
            locais = request.POST.getlist('local[]')
            horarios = request.POST.getlist('horario[]')
            entrevistados = request.POST.getlist('entrevistados[]')
            
            # Agrupa e salva os que foram preenchidos
            for loc, hor, ent in zip(locais, horarios, entrevistados):
                if loc or ent: # Só salva se tiver digitado algo
                    horario_valido = hor if hor else None
                    AgendaPauta.objects.create(
                        pauta=nova_pauta, local=loc, horario=horario_valido, entrevistados=ent
                    )
                    
            return redirect('lista_pautas')
    else:
        form = PautaForm()
        
    return render(request, 'core/pauta_form.html', {'form': form})

@login_required(login_url='login')
@permission_required('core.change_pauta', raise_exception=True)
def editar_pauta(request, pauta_id):
    pauta = get_object_or_404(Pauta, id=pauta_id)
    
    if request.method == 'POST':
        form = PautaForm(request.POST, instance=pauta)
        if form.is_valid():
            pauta_atualizada = form.save(commit=False)
            pauta_atualizada.editado_por = request.user
            pauta_atualizada.data_edicao = timezone.now()
            pauta_atualizada.save()
            
            # Atualiza as agendas dinâmicas: remove as antigas e recria com os novos dados enviados
            pauta.agendas.all().delete()
            locais = request.POST.getlist('local[]')
            horarios = request.POST.getlist('horario[]')
            entrevistados = request.POST.getlist('entrevistados[]')
            
            for loc, hor, ent in zip(locais, horarios, entrevistados):
                if loc or ent:
                    horario_valido = hor if hor else None
                    AgendaPauta.objects.create(
                        pauta=pauta_atualizada, local=loc, horario=horario_valido, entrevistados=ent
                    )
                    
            return redirect('ler_pauta', pauta_id=pauta.id)
    else:
        form = PautaForm(instance=pauta)
        
    return render(request, 'core/pauta_form.html', {'form': form, 'pauta': pauta, 'editando': True})