--All configuration relating to food and drinks
local config = {}

config.Bread = {
    Animation = "Eat";
    Sound = "SoftChew";
    Time = 3;
    Uses = 15;

    OnEmpty = {
        Delete = true;
    };
}

config.Cheburek = {
    Animation = "Eat";
    Sound = "SoftChew";
    Time = 3;
    Uses = 5;

    OnEmpty = {
        Delete = true;
    };
}

config.ColaBottle = {
    Animation = "Drink";
    Sound = "Drink";
    Time = 3;
    Uses = 5;

    OnEmpty = {
        Warning = "This bottle is empty!";
    };
}

config.ColaLarge = {
    Animation = "Drink";
    Sound = "Drink";
    Time = 3;
    Uses = 5;

    OnEmpty = {
        DestroyParts = {
            "Fill";
        };
        ReplaceWith = "GlassLarge";
        Warning = "This glass is empty!";
    };
}

config.ColaMedium = {
    Animation = "Drink";
    Sound = "Drink";
    Time = 3;
    Uses = 4;

    OnEmpty = {
        DestroyParts = {
            "Fill";
        };
        ReplaceWith = "GlassMedium";
        Warning = "This glass is empty!";
    };
}

config.ColaSmall = {
    Animation = "Drink";
    Sound = "Drink";
    Time = 3;
    Uses = 3;

    OnEmpty = {
        DestroyParts = {
            "Fill";
        };
        ReplaceWith = "GlassSmall";
        Warning = "This glass is empty!";
    };
}

config.CreamBottle = {
    Animation = "Drink";
    Sound = "Drink";
    Time = 3;
    Uses = 5;

    OnEmpty = {
        Warning = "This bottle is empty!";
    };
}

config.CreamLarge = {
    Animation = "Drink";
    Sound = "Drink";
    Time = 3;
    Uses = 5;

    OnEmpty = {
        DestroyParts = {
            "Fill";
        };
        ReplaceWith = "GlassLarge";
        Warning = "This glass is empty!";
    };
}

config.CreamMedium = {
    Animation = "Drink";
    Sound = "Drink";
    Time = 3;
    Uses = 4;

    OnEmpty = {
        DestroyParts = {
            "Fill";
        };
        ReplaceWith = "GlassMedium";
        Warning = "This glass is empty!";
    };
}

config.CreamSmall = {
    Animation = "Drink";
    Sound = "Drink";
    Time = 3;
    Uses = 3;

    OnEmpty = {
        DestroyParts = {
            "Fill";
        };
        ReplaceWith = "GlassSmall";
        Warning = "This glass is empty!";
    };
}

config.Croissant = {
    Animation = "Eat";
    Sound = "SoftChew";
    Time = 3;
    Uses = 3;

    OnEmpty = {
        Delete = true;
    };
}

config.Danish = {
    Animation = "Eat";
    Sound = "SoftChew";
    Time = 3;
    Uses = 4;

    OnEmpty = {
        Delete = true;
    };
}

config.Donut = {
    Animation = "Eat";
    Sound = "SoftChew";
    Time = 3;
    Uses = 3;

    OnEmpty = {
        Delete = true;
    };
}

config.GlassLarge = {
    Animation = "Drink";
    Sound = "Drink";
    Time = 3;
    Uses = 0;

    OnEmpty = {
        Warning = "This glass is empty!";
    };
}

config.GlassMedium = {
    Animation = "Drink";
    Sound = "Drink";
    Time = 3;
    Uses = 0;

    OnEmpty = {
        Warning = "This glass is empty!";
    };
}

config.GlassSmall = {
    Animation = "Drink";
    Sound = "Drink";
    Time = 3;
    Uses = 0;

    OnEmpty = {
        Warning = "This glass is empty!";
    };
}

config.HotDog = {
    Animation = "Eat";
    Sound = "SoftChew";
    Time = 3;
    Uses = 4;

    OnEmpty = {
        Delete = true;
    };
}

config.KaliBottle = {
    Animation = "Drink";
    Sound = "Drink";
    Time = 3;
    Uses = 5;

    OnEmpty = {
        Warning = "This bottle is empty!";
    };
}

config.KaliLarge = {
    Animation = "Drink";
    Sound = "Drink";
    Time = 3;
    Uses = 5;

    OnEmpty = {
        DestroyParts = {
            "Fill";
        };
        ReplaceWith = "GlassLarge";
        Warning = "This glass is empty!";
    };
}

config.KaliMedium = {
    Animation = "Drink";
    Sound = "Drink";
    Time = 3;
    Uses = 4;

    OnEmpty = {
        DestroyParts = {
            "Fill";
        };
        ReplaceWith = "GlassMedium";
        Warning = "This glass is empty!";
    };
}

config.KaliSmall = {
    Animation = "Drink";
    Sound = "Drink";
    Time = 3;
    Uses = 3;

    OnEmpty = {
        DestroyParts = {
            "Fill";
        };
        ReplaceWith = "GlassSmall";
        Warning = "This glass is empty!";
    };
}

config.KvasBottle = {
    Animation = "Drink";
    Sound = "Drink";
    Time = 3;
    Uses = 5;

    OnEmpty = {
        Warning = "This bottle is empty!";
    };
}

config.KvasLarge = {
    Animation = "Drink";
    Sound = "Drink";
    Time = 3;
    Uses = 5;

    OnEmpty = {
        DestroyParts = {
            "Fill";
        };
        ReplaceWith = "GlassLarge";
        Warning = "This glass is empty!";
    };
}

config.KvasMedium = {
    Animation = "Drink";
    Sound = "Drink";
    Time = 3;
    Uses = 4;

    OnEmpty = {
        DestroyParts = {
            "Fill";
        };
        ReplaceWith = "GlassMedium";
        Warning = "This glass is empty!";
    };
}

config.KvasSmall = {
    Animation = "Drink";
    Sound = "Drink";
    Time = 3;
    Uses = 3;

    OnEmpty = {
        DestroyParts = {
            "Fill";
        };
        ReplaceWith = "GlassSmall";
        Warning = "This glass is empty!";
    };
}

config.MilkLarge = {
    Animation = "Drink";
    Sound = "Drink";
    Time = 3;
    Uses = 5;

    OnEmpty = {
        DestroyParts = {
            "Fill";
        };
        ReplaceWith = "GlassLarge";
        Warning = "This glass is empty!";
    };
}

config.MilkMedium = {
    Animation = "Drink";
    Sound = "Drink";
    Time = 3;
    Uses = 4;

    OnEmpty = {
        DestroyParts = {
            "Fill";
        };
        ReplaceWith = "GlassMedium";
        Warning = "This glass is empty!";
    };
}

config.MilkSmall = {
    Animation = "Drink";
    Sound = "Drink";
    Time = 3;
    Uses = 3;

    OnEmpty = {
        DestroyParts = {
            "Fill";
        };
        ReplaceWith = "GlassSmall";
        Warning = "This glass is empty!";
    };
}

config.PacattiBottle = {
    Animation = "Drink";
    Sound = "Drink";
    Time = 3;
    Uses = 5;

    OnEmpty = {
        Warning = "This bottle is empty!";
    };
}

config.PacattiLarge = {
    Animation = "Drink";
    Sound = "Drink";
    Time = 3;
    Uses = 5;

    OnEmpty = {
        DestroyParts = {
            "Fill";
        };
        ReplaceWith = "GlassLarge";
        Warning = "This glass is empty!";
    };
}

config.PacattiMedium = {
    Animation = "Drink";
    Sound = "Drink";
    Time = 3;
    Uses = 4;

    OnEmpty = {
        DestroyParts = {
            "Fill";
        };
        ReplaceWith = "GlassMedium";
        Warning = "This glass is empty!";
    };
}

config.PacattiSmall = {
    Animation = "Drink";
    Sound = "Drink";
    Time = 3;
    Uses = 3;

    OnEmpty = {
        DestroyParts = {
            "Fill";
        };
        ReplaceWith = "GlassSmall";
        Warning = "This glass is empty!";
    };
}

config.Sandwich = {
    Animation = "Eat";
    Sound = "SoftChew";
    Time = 3;
    Uses = 5;

    OnEmpty = {
        Delete = true;
    };
}

return config