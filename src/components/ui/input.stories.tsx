import type { Meta, StoryObj } from "@storybook/nextjs-vite";

import { Input } from "./input";
import { Label } from "./label";

const meta = {
  title: "UI/Input",
  component: Input,
  args: {
    placeholder: "nome@exemplo.com",
    type: "email",
  },
  argTypes: {
    type: { control: "select", options: ["text", "email", "password"] },
    disabled: { control: "boolean" },
  },
} satisfies Meta<typeof Input>;

export default meta;

type Story = StoryObj<typeof meta>;

export const Default: Story = {};

export const WithLabel: Story = {
  render: (args) => (
    <div className="grid w-72 gap-2">
      <Label htmlFor="email">E-mail</Label>
      <Input id="email" {...args} />
    </div>
  ),
};

export const Invalid: Story = {
  args: { "aria-invalid": true, defaultValue: "nome@" },
};

export const Disabled: Story = {
  args: { disabled: true },
};
