from django.contrib.auth import login, logout, authenticate
from django.contrib.auth.models import User
from django.http import HttpResponseRedirect, HttpResponse
from django.shortcuts import get_object_or_404, redirect
from django.shortcuts import render
from django.urls import reverse
from django.contrib.auth.hashers import make_password

from concert.forms import LoginForm, SignUpForm
from concert.models import Concert, ConcertAttending
import requests as req
import os


def signup(request):
    if request.method == "POST":
        username = request.POST.get("username")
        password = request.POST.get("password")
        try:
            User.objects.get(username=username)
            return render(
                request,
                "signup.html",
                {"form": SignUpForm, "message": "User already exists"},
            )
        except User.DoesNotExist:
            user = User.objects.create(
                username=username, password=make_password(password)
            )
            login(request, user)
            return HttpResponseRedirect(reverse("index"))
    return render(request, "signup.html", {"form": SignUpForm})


def index(request):
    return render(request, "index.html")


def songs(request):
    songs = req.get(f"{os.environ.get('SONG_SERVICE_URL')}/song").json()
    return render(request, "songs.html", {"songs": songs["songs"]})


def photos(request):
    photos = req.get(f"{os.environ.get('PICTURE_SERVICE_URL')}/picture").json()
    return render(request, "photos.html", {"photos": photos})


def login_view(request):
    if request.method == "POST":
        username = request.POST.get("username")
        password = request.POST.get("password")
        try:
            User.objects.get(username=username)
            user = authenticate(username=username, password=password)
            if user:
                login(request, user)
                return HttpResponseRedirect(reverse("index"))
        except User.DoesNotExist:
            return render(request, "login.html", {"form": LoginForm})
    return render(request, "login.html", {"form": LoginForm})


def logout_view(request):
    logout(request)
    return HttpResponseRedirect(reverse("login"))


def concerts(request):
    user = request.user
    if user.is_authenticated:
        lst_of_concert = []
        concert_objects = Concert.objects.all()
        for item in concert_objects:
            try:
                status = item.attendee.filter(user=request.user).first().attending
            except:
                status = "-"
            lst_of_concert.append({"concert": item, "status": status})
        return render(
            request, "concerts.html", {"concerts": lst_of_concert}
        )  # {insert code to render the `concerts.html` page with the data of {"concerts": lst_of_concert}}
    else:
        return HttpResponseRedirect(reverse("login"))


def concert_detail(request, id):
    if request.user.is_authenticated:
        obj = Concert.objects.get(pk=id)
        try:
            status = obj.attendee.filter(user=request.user).first().attending
        except:
            status = "-"
        return render(
            request,
            "concert_detail.html",
            {
                "concert_details": obj,
                "status": status,
                "attending_choices": ConcertAttending.AttendingChoices.choices,
            },
        )
    else:
        return HttpResponseRedirect(reverse("login"))
    pass


def concert_attendee(request):
    if request.user.is_authenticated:
        if request.method == "POST":
            concert_id = request.POST.get("concert_id")
            attendee_status = request.POST.get("attendee_choice")
            concert_attendee_object = ConcertAttending.objects.filter(
                concert_id=concert_id, user=request.user
            ).first()
            if concert_attendee_object:
                concert_attendee_object.attending = attendee_status
                concert_attendee_object.save()
            else:
                ConcertAttending.objects.create(
                    concert_id=concert_id, user=request.user, attending=attendee_status
                )

        return HttpResponseRedirect(reverse("concerts"))
    else:
        return HttpResponseRedirect(reverse("index"))
