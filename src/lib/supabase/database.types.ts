export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

export type Database = {
  public: {
    Tables: {
      church_member_congregations: {
        Row: {
          church_id: string;
          congregation_id: string;
          created_at: string;
          member_id: string;
        };
        Insert: {
          church_id: string;
          congregation_id: string;
          created_at?: string;
          member_id: string;
        };
        Update: {
          church_id?: string;
          congregation_id?: string;
          created_at?: string;
          member_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: "church_member_congregations_church_id_congregation_id_fkey";
            columns: ["church_id", "congregation_id"];
            isOneToOne: false;
            referencedRelation: "congregations";
            referencedColumns: ["church_id", "id"];
          },
          {
            foreignKeyName: "church_member_congregations_church_id_member_id_fkey";
            columns: ["church_id", "member_id"];
            isOneToOne: false;
            referencedRelation: "church_members";
            referencedColumns: ["church_id", "id"];
          },
        ];
      };
      church_members: {
        Row: {
          all_congregations: boolean;
          church_id: string;
          created_at: string;
          id: string;
          role: string;
          status: string;
          updated_at: string;
          user_id: string;
        };
        Insert: {
          all_congregations?: boolean;
          church_id: string;
          created_at?: string;
          id?: string;
          role: string;
          status?: string;
          updated_at?: string;
          user_id: string;
        };
        Update: {
          all_congregations?: boolean;
          church_id?: string;
          created_at?: string;
          id?: string;
          role?: string;
          status?: string;
          updated_at?: string;
          user_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: "church_members_church_id_fkey";
            columns: ["church_id"];
            isOneToOne: false;
            referencedRelation: "churches";
            referencedColumns: ["id"];
          },
        ];
      };
      churches: {
        Row: {
          archived_at: string | null;
          city: string | null;
          created_at: string;
          created_by: string | null;
          denomination: string | null;
          document: string | null;
          id: string;
          logo_path: string | null;
          name: string;
          religious_fields_enabled: boolean;
          slug: string;
          state: string | null;
          timezone: string;
          updated_at: string;
        };
        Insert: {
          archived_at?: string | null;
          city?: string | null;
          created_at?: string;
          created_by?: string | null;
          denomination?: string | null;
          document?: string | null;
          id?: string;
          logo_path?: string | null;
          name: string;
          religious_fields_enabled?: boolean;
          slug: string;
          state?: string | null;
          timezone?: string;
          updated_at?: string;
        };
        Update: {
          archived_at?: string | null;
          city?: string | null;
          created_at?: string;
          created_by?: string | null;
          denomination?: string | null;
          document?: string | null;
          id?: string;
          logo_path?: string | null;
          name?: string;
          religious_fields_enabled?: boolean;
          slug?: string;
          state?: string | null;
          timezone?: string;
          updated_at?: string;
        };
        Relationships: [];
      };
      class_teachers: {
        Row: {
          church_id: string;
          class_id: string;
          created_at: string;
          ended_on: string | null;
          id: string;
          member_id: string | null;
          person_id: string;
          role: string;
          started_on: string;
          updated_at: string;
        };
        Insert: {
          church_id: string;
          class_id: string;
          created_at?: string;
          ended_on?: string | null;
          id?: string;
          member_id?: string | null;
          person_id: string;
          role?: string;
          started_on: string;
          updated_at?: string;
        };
        Update: {
          church_id?: string;
          class_id?: string;
          created_at?: string;
          ended_on?: string | null;
          id?: string;
          member_id?: string | null;
          person_id?: string;
          role?: string;
          started_on?: string;
          updated_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: "class_teachers_church_id_class_id_fkey";
            columns: ["church_id", "class_id"];
            isOneToOne: false;
            referencedRelation: "classes";
            referencedColumns: ["church_id", "id"];
          },
          {
            foreignKeyName: "class_teachers_church_id_fkey";
            columns: ["church_id"];
            isOneToOne: false;
            referencedRelation: "churches";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "class_teachers_church_id_member_id_fkey";
            columns: ["church_id", "member_id"];
            isOneToOne: false;
            referencedRelation: "church_members";
            referencedColumns: ["church_id", "id"];
          },
          {
            foreignKeyName: "class_teachers_church_id_person_id_fkey";
            columns: ["church_id", "person_id"];
            isOneToOne: false;
            referencedRelation: "people";
            referencedColumns: ["church_id", "id"];
          },
        ];
      };
      classes: {
        Row: {
          archived_at: string | null;
          church_id: string;
          congregation_id: string;
          created_at: string;
          id: string;
          max_age: number | null;
          min_age: number | null;
          name: string;
          room: string | null;
          sort_order: number;
          updated_at: string;
        };
        Insert: {
          archived_at?: string | null;
          church_id: string;
          congregation_id: string;
          created_at?: string;
          id?: string;
          max_age?: number | null;
          min_age?: number | null;
          name: string;
          room?: string | null;
          sort_order?: number;
          updated_at?: string;
        };
        Update: {
          archived_at?: string | null;
          church_id?: string;
          congregation_id?: string;
          created_at?: string;
          id?: string;
          max_age?: number | null;
          min_age?: number | null;
          name?: string;
          room?: string | null;
          sort_order?: number;
          updated_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: "classes_church_id_congregation_id_fkey";
            columns: ["church_id", "congregation_id"];
            isOneToOne: false;
            referencedRelation: "congregations";
            referencedColumns: ["church_id", "id"];
          },
          {
            foreignKeyName: "classes_church_id_fkey";
            columns: ["church_id"];
            isOneToOne: false;
            referencedRelation: "churches";
            referencedColumns: ["id"];
          },
        ];
      };
      congregations: {
        Row: {
          address_line: string | null;
          archived_at: string | null;
          church_id: string;
          city: string | null;
          created_at: string;
          id: string;
          is_headquarters: boolean;
          name: string;
          neighborhood: string | null;
          postal_code: string | null;
          state: string | null;
          updated_at: string;
        };
        Insert: {
          address_line?: string | null;
          archived_at?: string | null;
          church_id: string;
          city?: string | null;
          created_at?: string;
          id?: string;
          is_headquarters?: boolean;
          name: string;
          neighborhood?: string | null;
          postal_code?: string | null;
          state?: string | null;
          updated_at?: string;
        };
        Update: {
          address_line?: string | null;
          archived_at?: string | null;
          church_id?: string;
          city?: string | null;
          created_at?: string;
          id?: string;
          is_headquarters?: boolean;
          name?: string;
          neighborhood?: string | null;
          postal_code?: string | null;
          state?: string | null;
          updated_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: "congregations_church_id_fkey";
            columns: ["church_id"];
            isOneToOne: false;
            referencedRelation: "churches";
            referencedColumns: ["id"];
          },
        ];
      };
      enrollments: {
        Row: {
          church_id: string;
          class_id: string;
          congregation_id: string;
          created_at: string;
          end_reason: string | null;
          ended_on: string | null;
          id: string;
          person_id: string;
          started_on: string;
          updated_at: string;
        };
        Insert: {
          church_id: string;
          class_id: string;
          congregation_id: string;
          created_at?: string;
          end_reason?: string | null;
          ended_on?: string | null;
          id?: string;
          person_id: string;
          started_on: string;
          updated_at?: string;
        };
        Update: {
          church_id?: string;
          class_id?: string;
          congregation_id?: string;
          created_at?: string;
          end_reason?: string | null;
          ended_on?: string | null;
          id?: string;
          person_id?: string;
          started_on?: string;
          updated_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: "enrollments_church_id_class_id_congregation_id_fkey";
            columns: ["church_id", "class_id", "congregation_id"];
            isOneToOne: false;
            referencedRelation: "classes";
            referencedColumns: ["church_id", "id", "congregation_id"];
          },
          {
            foreignKeyName: "enrollments_church_id_fkey";
            columns: ["church_id"];
            isOneToOne: false;
            referencedRelation: "churches";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "enrollments_church_id_person_id_fkey";
            columns: ["church_id", "person_id"];
            isOneToOne: false;
            referencedRelation: "people";
            referencedColumns: ["church_id", "id"];
          },
        ];
      };
      people: {
        Row: {
          address_line: string | null;
          anonymized_at: string | null;
          birth_date: string | null;
          church_id: string;
          city: string | null;
          created_at: string;
          created_by: string | null;
          email: string | null;
          full_name: string | null;
          gender: string | null;
          guardian_person_id: string | null;
          id: string;
          invited_by_person_id: string | null;
          neighborhood: string | null;
          notes: string | null;
          phone: string | null;
          postal_code: string | null;
          primary_congregation_id: string | null;
          search_name: string | null;
          state: string | null;
          updated_at: string;
        };
        Insert: {
          address_line?: string | null;
          anonymized_at?: string | null;
          birth_date?: string | null;
          church_id: string;
          city?: string | null;
          created_at?: string;
          created_by?: string | null;
          email?: string | null;
          full_name?: string | null;
          gender?: string | null;
          guardian_person_id?: string | null;
          id?: string;
          invited_by_person_id?: string | null;
          neighborhood?: string | null;
          notes?: string | null;
          phone?: string | null;
          postal_code?: string | null;
          primary_congregation_id?: string | null;
          search_name?: never;
          state?: string | null;
          updated_at?: string;
        };
        Update: {
          address_line?: string | null;
          anonymized_at?: string | null;
          birth_date?: string | null;
          church_id?: string;
          city?: string | null;
          created_at?: string;
          created_by?: string | null;
          email?: string | null;
          full_name?: string | null;
          gender?: string | null;
          guardian_person_id?: string | null;
          id?: string;
          invited_by_person_id?: string | null;
          neighborhood?: string | null;
          notes?: string | null;
          phone?: string | null;
          postal_code?: string | null;
          primary_congregation_id?: string | null;
          search_name?: never;
          state?: string | null;
          updated_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: "people_church_id_fkey";
            columns: ["church_id"];
            isOneToOne: false;
            referencedRelation: "churches";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "people_church_id_guardian_person_id_fkey";
            columns: ["church_id", "guardian_person_id"];
            isOneToOne: false;
            referencedRelation: "people";
            referencedColumns: ["church_id", "id"];
          },
          {
            foreignKeyName: "people_church_id_invited_by_person_id_fkey";
            columns: ["church_id", "invited_by_person_id"];
            isOneToOne: false;
            referencedRelation: "people";
            referencedColumns: ["church_id", "id"];
          },
          {
            foreignKeyName: "people_church_id_primary_congregation_id_fkey";
            columns: ["church_id", "primary_congregation_id"];
            isOneToOne: false;
            referencedRelation: "congregations";
            referencedColumns: ["church_id", "id"];
          },
        ];
      };
      person_religious_info: {
        Row: {
          baptism_date: string | null;
          baptized: boolean | null;
          church_id: string;
          created_at: string;
          is_church_member: boolean | null;
          origin_church: string | null;
          person_id: string;
          updated_at: string;
        };
        Insert: {
          baptism_date?: string | null;
          baptized?: boolean | null;
          church_id: string;
          created_at?: string;
          is_church_member?: boolean | null;
          origin_church?: string | null;
          person_id: string;
          updated_at?: string;
        };
        Update: {
          baptism_date?: string | null;
          baptized?: boolean | null;
          church_id?: string;
          created_at?: string;
          is_church_member?: boolean | null;
          origin_church?: string | null;
          person_id?: string;
          updated_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: "person_religious_info_church_id_person_id_fkey";
            columns: ["church_id", "person_id"];
            isOneToOne: false;
            referencedRelation: "people";
            referencedColumns: ["church_id", "id"];
          },
        ];
      };
      user_profiles: {
        Row: {
          active_church_id: string | null;
          created_at: string;
          full_name: string | null;
          updated_at: string;
          user_id: string;
        };
        Insert: {
          active_church_id?: string | null;
          created_at?: string;
          full_name?: string | null;
          updated_at?: string;
          user_id: string;
        };
        Update: {
          active_church_id?: string | null;
          created_at?: string;
          full_name?: string | null;
          updated_at?: string;
          user_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: "user_profiles_active_church_id_fkey";
            columns: ["active_church_id"];
            isOneToOne: false;
            referencedRelation: "churches";
            referencedColumns: ["id"];
          },
        ];
      };
    };
    Views: {
      class_roster: {
        Row: {
          age: number | null;
          birth_day: number | null;
          birth_month: number | null;
          church_id: string | null;
          class_id: string | null;
          enrollment_id: string | null;
          full_name: string | null;
          person_id: string | null;
          phone: string | null;
          phone_is_guardian: boolean | null;
          started_on: string | null;
        };
        Relationships: [];
      };
    };
    Functions: {
      anonymize_person: { Args: { person_id: string }; Returns: undefined };
      current_capabilities: { Args: Record<PropertyKey, never>; Returns: string[] };
    };
    Enums: {
      [_ in never]: never;
    };
    CompositeTypes: {
      [_ in never]: never;
    };
  };
};

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">;

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">];

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R;
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] & DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R;
      }
      ? R
      : never
    : never;

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    keyof DefaultSchema["Tables"] | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I;
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I;
      }
      ? I
      : never
    : never;

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    keyof DefaultSchema["Tables"] | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U;
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U;
      }
      ? U
      : never
    : never;

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    keyof DefaultSchema["Enums"] | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never;

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    keyof DefaultSchema["CompositeTypes"] | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never;

export const Constants = {
  public: {
    Enums: {},
  },
} as const;
